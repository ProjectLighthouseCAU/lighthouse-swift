#if canImport(WebSocketKit)
import Foundation
import Logging
import NIO
import WebSocketKit

private let log = Logger(label: "LighthouseWebSocket.WebSocketKitWebSocket")

public final class _WebSocketKitWebSocket: WebSocketProtocol {
    private let url: URL
    private var webSocket: WebSocketKit.WebSocket?

    /// The event loop group on which the WebSocket connection runs.
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)

    public init(url: URL) {
        self.url = url
    }

    deinit {
        _ = webSocket?.close()
        eventLoopGroup.shutdownGracefully { error in
            guard let error = error else { return }
            log.error("Error while shutting down event loop group: \(error)")
        }
    }

    public func connect() async throws {
        webSocket = try await withCheckedThrowingContinuation { continuation in
            WebSocketKit.WebSocket.connect(to: url, on: eventLoopGroup) { ws in
                continuation.resume(returning: ws)
            }.whenFailure { error in
                continuation.resume(throwing: error)
            }
        }
    }

    public func onBinary(_ handler: @escaping (Data) -> Void) throws {
        guard let webSocket else { throw WebSocketError.notConnectedYet }
        webSocket.onBinary { (_, buf) in
            var buf = buf
            guard let data = buf.readData(length: buf.readableBytes) else {
                log.warning("Could not read data from WebSocket")
                return
            }

            handler(data)
        }
    }

    public func send(_ data: Data) async throws {
        guard let webSocket else { throw WebSocketError.notConnectedYet }
        let promise = eventLoopGroup.next().makePromise(of: Void.self)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            promise.futureResult.whenComplete {
                continuation.resume(with: $0)
            }
            webSocket.send(Array(data), promise: promise)
        }
    }
}
#endif
