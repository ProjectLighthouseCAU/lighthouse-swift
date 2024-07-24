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
    private var responseHandlers: [Int: (Data) throws -> Void] = [:]

    /// The next request id.
    private var requestId: Int = 0
    /// The WebSocket connection.
    private var webSocket: WebSocket?

    /// Instantiates the ``Lighthouse`` wrapper with the given credentials and
    /// URL.
    /// 
    /// Note that this does not initiate a connection yet, clients should call
    /// ``connect()`` to do this.
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
    ///
    /// This uses the previously provided authentication credentials and URL.
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
                let envelope = try MessagePackDecoder().decode(ServerMessage<Nil>.self, from: data)
                if let handler = responseHandlers[envelope.requestId] {
                    try handler(data)
                } else {
                    log.warning("Message left unhandled: \(envelope.requestId)")
                }
            } catch {
                log.warning("Error while decoding message: \(error)")
            }
        } 
        
        self.webSocket = webSocket
    }

    /// Sends the given frame to the lighthouse.
    @discardableResult
    public func putModel(frame: Frame) async throws -> ServerMessage<Nil> {
        try await perform(verb: .put, path: ["user", authentication.username, "model"], payload: Model.frame(frame))
    }

    /// Streams the current user's model.
    public func streamModel() async throws -> AsyncStream<ServerMessage<Model>> {
        try await stream(path: ["user", authentication.username, "model"])
    }

    /// Performs a `POST` request to the given path.
    ///
    /// This creates and updates the resource at the given path, effectively
    /// combining `PUT` and `CREATE`. Requires `CREATE` and `WRITE` permission.
    @discardableResult
    public func post<Payload>(path: [String], payload: Payload) async throws -> ServerMessage<Nil>
    where Payload: Encodable {
        try await perform(verb: .post, path: path, payload: payload)
    }

    /// Performs a `PUT` request to the given path.
    ///
    /// This updates the resource at the given path with the given payload.
    @discardableResult
    public func put<Payload>(path: [String], payload: Payload) async throws -> ServerMessage<Nil>
    where Payload: Encodable {
        try await perform(verb: .put, path: path, payload: payload)
    }

    /// Performs a `CREATE` request to the given path.
    /// 
    /// This creates a resource at the given path. Requires `CREATE` permission.
    @discardableResult
    public func create(path: [String]) async throws -> ServerMessage<Nil> {
        try await perform(verb: .create, path: path)
    }

    /// Performs a `DELETE` request to the given path.
    /// 
    /// This deletes the resource at the given path. Requires `DELETE` permission.
    @discardableResult
    public func delete(path: [String]) async throws -> ServerMessage<Nil> {
        try await perform(verb: .delete, path: path)
    }

    /// Performs a `MKDIR` request to the given path.
    /// 
    /// This creates a directory at the given path. Requires `CREATE` permission.
    @discardableResult
    public func mkdir(path: [String]) async throws -> ServerMessage<Nil> {
        try await perform(verb: .mkdir, path: path)
    }

    /// Performs a `LIST` request to the given path.
    /// 
    /// This lists the directory at the given path. Requires `READ` permission.
    public func list(path: [String]) async throws -> ServerMessage<DirectoryTree> {
        try await perform(verb: .list, path: path)
    }

    /// Performs a `GET` request to the given path.
    /// 
    /// This fetches the resource at the given path. Requires `READ` permission.
    public func get<ResponsePayload>(path: [String], as type: ResponsePayload.Type) async throws -> ServerMessage<ResponsePayload>
    where ResponsePayload: Decodable {
        try await perform(verb: .get, path: path)
    }

    /// Performs a `LINK` request to the given paths.
    /// 
    /// This links the given source to the given destination path.
    @discardableResult
    public func link(path source: [String], to dest: [String]) async throws -> ServerMessage<Nil> {
        try await perform(verb: .link, path: dest, payload: source)
    }

    /// Performs an `UNLINK` request to the given paths.
    /// 
    /// This unlinks the given source from the given destination path.
    @discardableResult
    public func unlink(path source: [String], to dest: [String]) async throws -> ServerMessage<Nil> {
        try await perform(verb: .unlink, path: dest, payload: source)
    }

    /// Performs a `STOP` request to the given path.
    ///
    /// This stops a stream.
    @discardableResult
    public func stop(path: [String]) async throws -> ServerMessage<Nil> {
        try await perform(verb: .stop, path: path)
    }

    /// Performs a one-off request to the lighthouse with an empty payload.
    @discardableResult
    public func perform<ResponsePayload>(verb: Verb, path: [String]) async throws -> ServerMessage<ResponsePayload>
    where ResponsePayload: Decodable {
        try await perform(verb: verb, path: path, payload: Nil())
    }

    /// Performs a one-off request to the lighthouse.
    @discardableResult
    public func perform<Payload, ResponsePayload>(verb: Verb, path: [String], payload: Payload) async throws -> ServerMessage<ResponsePayload>
    where Payload: Encodable, ResponsePayload: Decodable {
        precondition(verb != .stream, "Lighthouse.perform may only be used for one-off requests, use Lighthouse.stream for streaming!")
        let requestId = try await send(verb: verb, path: path, payload: payload)
        let response = await receiveSingle(for: requestId, as: ResponsePayload.self)
        try response.check()
        return response
    }

    /// Performs a streaming request to the lighthouse with an empty payload.
    public func stream<ResponsePayload>(path: [String]) async throws -> AsyncStream<ServerMessage<ResponsePayload>>
    where ResponsePayload: Decodable {
        try await stream(path: path, payload: Nil())
    }

    /// Performs a streaming request to the lighthouse.
    public func stream<Payload, ResponsePayload>(path: [String], payload: Payload) async throws -> AsyncStream<ServerMessage<ResponsePayload>>
    where Payload: Encodable, ResponsePayload: Decodable {
        let requestId = try await send(verb: .stream, path: path, payload: payload)
        return receiveStreaming(for: requestId, as: ResponsePayload.self)
    }

    /// Sends the given request to the lighthouse and reeturns the request id.
    @discardableResult
    private func send<Payload>(verb: Verb, path: [String], payload: Payload) async throws -> Int
    where Payload: Encodable {
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
    private func receiveStreaming<ResponsePayload>(for requestId: Int, as type: ResponsePayload.Type) -> AsyncStream<ServerMessage<ResponsePayload>>
    where ResponsePayload: Decodable {
        AsyncStream { continuation in
            responseHandlers[requestId] = { data in
                let message = try MessagePackDecoder().decode(ServerMessage<ResponsePayload>.self, from: data)
                continuation.yield(message)
            }
            continuation.onTermination = { [weak self] _ in
                self?.responseHandlers[requestId] = nil
            }
        }
    }

    /// Receives a single response for the given id.
    private func receiveSingle<ResponsePayload>(for requestId: Int, as type: ResponsePayload.Type) async -> ServerMessage<ResponsePayload>
    where ResponsePayload: Decodable {
        await withCheckedContinuation { continuation in
            responseHandlers[requestId] = { [weak self] data in
                let message = try MessagePackDecoder().decode(ServerMessage<ResponsePayload>.self, from: data)
                self?.responseHandlers[requestId] = nil
                continuation.resume(returning: message)
            }
        }
    }
}
