import Foundation
import Logging
import MessagePack
import NIO
import WebSocketKit
import LighthouseProtocol

private let log = Logger(label: "LighthouseClient.Lighthouse")

// TODO: Properly link protocol types after https://github.com/swiftlang/swift-docc/issues/208

/// A connection to the Project Lighthouse server.
///
/// The ``Lighthouse`` class provides a high-level interface around the
/// WebSocket-based Project Lighthouse API. After connecting, clients can
/// perform CRUD requests, most notably sending and streaming `Frame`s and
/// `InputEvent`s.
///
/// To connect, provide your credentials by creating a `Authentication`,
/// instantiate a ``Lighthouse`` and call ``connect()``:
///
/// ```swift
/// let auth = Authentication(username: "your username", token: "your token")
/// let lh = Lighthouse(authentication: auth)
///
/// try await lh.connect()
/// ```
///
/// To stream a resource, such as the user model for input events, use the
/// corresponding methods, e.g. ``stream(path:payload:)`` or ``streamModel()``:
/// 
/// ```swift
/// Task {
///     let stream = try await lh.streamModel()
///     for await message in stream {
///         if case let .inputEvent(input) = message.payload {
///             log.info("Got input \(input)")
///         }
///     }
/// }
/// ```
///
/// To send colored frames to the server, use methods such as ``putModel(frame:)``:
/// 
/// ```swift
/// while true {
///     log.info("Sending frame")
///     try await lh.putModel(frame: Frame(fill: .random()))
///     try await Task.sleep(for: .seconds(1))
/// }
/// ```
public class Lighthouse {
    /// The WebSocket URL of the connected lighthouse server.
    private let url: URL
    /// The user's authentication credentials.
    private let authentication: Authentication
    /// The event loop group on which the WebSocket connection runs.
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)

    /// The response handlers, keyed by request id.
    private var responseHandlers: [Int: (ServerMessage) -> Void] = [:]

    /// The next request id.
    private var requestId: Int = 0
    /// The WebSocket connection.
    private var webSocket: WebSocket?

    public init(
        authentication: Authentication,
        url: URL = lighthouseUrl
    ) {
        self.authentication = authentication
        self.url = url
    }

    deinit {
        _ = webSocket?.close()
        eventLoopGroup.shutdownGracefully { error in
            guard let error = error else { return }
            log.error("Error while shutting down event loop group: \(error)")
        }
    }

    /// Connects to the lighthouse.
    public func connect() async throws {
        let webSocket = try await withCheckedThrowingContinuation { continuation in
            WebSocket.connect(to: url, on: eventLoopGroup) { ws in
                continuation.resume(returning: ws)
            }.whenFailure { error in
                continuation.resume(throwing: error)
            }
        }

        webSocket.onBinary { [unowned self] (_, buf) in
            var buf = buf
            guard let data = buf.readData(length: buf.readableBytes) else {
                log.warning("Could not read data from WebSocket")
                return
            }

            do {
                let message = try MessagePackDecoder().decode(ServerMessage.self, from: data)
                if let handler = responseHandlers[message.requestId] {
                    handler(message)
                } else {
                    log.warning("Message left unhandled: \(message.requestId)")
                }
            } catch {
                log.warning("Error while decoding message: \(error)")
            }
        } 
        
        self.webSocket = webSocket
    }

    /// Sends the given frame to the lighthouse.
    public func putModel(frame: Frame) async throws {
        try await perform(verb: "PUT", path: ["user", authentication.username, "model"], payload: .frame(frame))
    }

    /// Streams the model.
    public func streamModel() async throws -> AsyncStream<ServerMessage> {
        try await stream(path: ["user", authentication.username, "model"])
    }

    /// Performs a PUT request to the given path.
    public func put(path: [String], payload: Payload = .other) async throws {
        try await perform(verb: "PUT", path: path, payload: payload)
    }

    /// Performs a one-off request to the lighthouse.
    @discardableResult
    public func perform(verb: String, path: [String], payload: Payload = .other) async throws -> ServerMessage {
        precondition(verb != "STREAM", "Lighthouse.perform may only be used for one-off requests, use Lighthouse.stream for streaming!")
        let requestId = try await send(verb: verb, path: path, payload: payload)
        let response = await receiveSingle(for: requestId)
        try response.check()
        return response
    }

    /// Performs a streaming request to the lighthouse.
    public func stream(path: [String], payload: Payload = .other) async throws -> AsyncStream<ServerMessage> {
        let requestId = try await send(verb: "STREAM", path: path, payload: payload)
        return receiveStreaming(for: requestId)
    }

    /// Sends the given request to the lighthouse and reeturns the request id.
    @discardableResult
    private func send(verb: String, path: [String], payload: Payload = .other) async throws -> Int {
        let requestId = nextRequestId()
        try await send(message: ClientMessage(
            requestId: requestId,
            verb: verb,
            path: path,
            authentication: authentication,
            payload: payload
        ))
        return requestId
    }

    /// Sends a message to the lighthouse.
    private func send<Message>(message: Message) async throws where Message: Encodable {
        let data = try MessagePackEncoder().encode(message)
        try await send(data: data)
    }

    /// Sends binary data to the lighthouse.
    private func send(data: Data) async throws {
        guard let webSocket = webSocket else { fatalError("Please call .connect() before sending data!") }
        let promise = eventLoopGroup.next().makePromise(of: Void.self)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            promise.futureResult.whenComplete {
                continuation.resume(with: $0)
            }
            webSocket.send(Array(data), promise: promise)
        }
    }

    /// Fetches the next request id for sending.
    private func nextRequestId() -> Int {
        let id = requestId
        requestId += 1
        return id
    }

    /// Receives a stream of responses for the given id.
    private func receiveStreaming(for requestId: Int) -> AsyncStream<ServerMessage> {
        AsyncStream { continuation in
            responseHandlers[requestId] = { message in
                continuation.yield(message)
            }
            continuation.onTermination = { [weak self] _ in
                self?.responseHandlers[requestId] = nil
            }
        }
    }

    /// Receives a single response for the given id.
    private func receiveSingle(for requestId: Int) async -> ServerMessage {
        await withCheckedContinuation { continuation in
            responseHandlers[requestId] = { [weak self] message in
                self?.responseHandlers[requestId] = nil
                continuation.resume(returning: message)
            }
        }
    }
}
