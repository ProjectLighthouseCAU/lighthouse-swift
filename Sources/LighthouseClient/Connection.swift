import Foundation
import NIO
import WebSocketKit

/// A connection to the lighthouse server.
public class Connection {
    private let authentication: Authentication
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    private var webSocket: WebSocket?

    public init(authentication: Authentication) {
        self.authentication = authentication
    }

    deinit {
        try! webSocket?.close().wait()
        try! eventLoopGroup.syncShutdownGracefully()
    }

    /// Connects to the lighthouse.
    public func connect() async throws {
        webSocket = try await withCheckedThrowingContinuation { continuation in
            WebSocket.connect(to: "wss://lighthouse.uni-kiel.de/websocket", on: eventLoopGroup) { ws in
                continuation.resume(returning: ws)
            }.whenFailure { error in
                continuation.resume(throwing: error)
            }
        }
    }

    /// Sends binary data to the lighthouse.
    public func send(data: Data) async {
        guard let webSocket = webSocket else { fatalError("Please call .connect() before sending data!") }
        webSocket.send(Array(data))
    }
}
