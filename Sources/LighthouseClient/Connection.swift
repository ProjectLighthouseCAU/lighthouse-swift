import Foundation
import Logging
import MessagePack
import NIO
import WebSocketKit
import LighthouseProtocol

private let log = Logger(label: "LighthouseClient.Connection")

/// A connection to the lighthouse server.
public class Connection {
    private let url: URL
    private let authentication: Authentication
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)

    private var inputListeners: [(Protocol.InputEvent) -> Void] = []
    private var displayListeners: [(Display) -> Void] = []
    private var messageListeners: [(Protocol.ServerMessage) -> Void] = []
    private var dataListeners: [(Data) -> Void] = []

    private var requestId: Int = 0
    private var webSocket: WebSocket?

    public init(
        authentication: Authentication,
        url: URL = lighthouseUrl
    ) {
        self.authentication = authentication
        self.url = url
        setUpListeners()
    }

    deinit {
        try! webSocket?.close().wait()
        try! eventLoopGroup.syncShutdownGracefully()
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

            for listener in dataListeners {
                listener(data)
            }
        } 
        
        self.webSocket = webSocket
    }

    /// Sends the given display to the lighthouse.
    public func send(display: Display) async throws {
        try await send(verb: "PUT", path: ["user", authentication.username, "model"], payload: .display(display))
    }

    /// Requests a stream of events (such as input) from the lighthouse.
    public func requestStream() async throws {
        try await send(verb: "STREAM", path: ["user", authentication.username, "model"])
    }

    /// Sends the given request to the lighthouse.
    public func send(verb: String, path: [String], payload: Protocol.Payload = .other) async throws {
        try await send(message: Protocol.ClientMessage(
            requestId: nextRequestId(),
            verb: verb,
            path: path,
            authentication: authentication,
            payload: payload
        ))
    }

    /// Sends a message to the lighthouse.
    public func send<Message>(message: Message) async throws where Message: Encodable {
        let data = try MessagePackEncoder().encode(message)
        try await send(data: data)
    }

    /// Sends binary data to the lighthouse.
    public func send(data: Data) async throws {
        guard let webSocket = webSocket else { fatalError("Please call .connect() before sending data!") }
        #if os(Linux)
        try await webSocket.send(Array(data))
        #else
        webSocket.send(Array(data))
        #endif
    }

    /// Fetches the next request id for sending.
    private func nextRequestId() -> Int {
        let id = requestId
        requestId += 1
        return id
    }

    /// Sets up the listeners for received messages.
    private func setUpListeners() {
        onData { [unowned self] data in
            do {
                let message = try MessagePackDecoder().decode(Protocol.ServerMessage.self, from: data)

                for listener in messageListeners {
                    listener(message)
                }
            } catch {
                log.warning("Error while decoding message: \(error)")
            }
        }

        onMessage { [unowned self] message in
            switch message.payload {
            case .inputEvent(let inputEvent):
                for listener in inputListeners {
                    listener(inputEvent)
                }
            case .display(let display):
                for listener in displayListeners {
                    listener(display)
                }
            default:
                break
            }
        }
    }

    /// Adds a listener for key/controller input.
    /// Will only fire if .requestStream() was called.
    public func onInput(action: @escaping (Protocol.InputEvent) -> Void) {
        inputListeners.append(action)
    }

    /// Adds a listener for displays.
    /// Will only fire if .requestStream() was called.
    public func onDisplay(action: @escaping (Display) -> Void) {
        displayListeners.append(action)
    }

    /// Adds a listener for generic messages.
    public func onMessage(action: @escaping (Protocol.ServerMessage) -> Void) {
        messageListeners.append(action)
    }

    /// Adds a listener for binary data.
    private func onData(action: @escaping (Data) -> Void) {
        dataListeners.append(action)
    }
}
