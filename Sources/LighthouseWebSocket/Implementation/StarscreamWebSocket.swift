#if canImport(Starscream)
import Foundation
import Logging
import Starscream

private let log = Logger(label: "LighthouseWebSocket.StarscreamWebSocket")

public final class _StarscreamWebSocket: WebSocketProtocol, Starscream.WebSocketDelegate {
    private var webSocket: Starscream.WebSocket
    private var connectHandlers: [(Result<Void, any Error>) -> Void] = []
    private var binaryMessageHandlers: [(Data) -> Void] = []
    
    public init(url: URL) {
        webSocket = Starscream.WebSocket(request: URLRequest(url: url))
        webSocket.delegate = self
    }
    
    public func connect() async throws {
        log.trace("Connecting")
        try await withCheckedThrowingContinuation { continuation in
            connectHandlers.append(continuation.resume(with:))
            webSocket.connect()
        }
    }
    
    public func onBinary(_ handler: @escaping (Data) -> Void) throws {
        log.trace("Adding binary message handler")
        binaryMessageHandlers.append(handler)
    }
    
    public func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        log.trace("Received WebSocketEvent \(event)")
        switch event {
        case .connected(_):
            while let handler = connectHandlers.popLast() {
                handler(.success(()))
            }
        case .error(let error):
            while let handler = connectHandlers.popLast() {
                handler(.failure(error ?? WebSocketError.unknown))
            }
        case .binary(let data):
            for handler in binaryMessageHandlers {
                handler(data)
            }
        default:
            break
        }
    }
    
    public func send(_ data: Data) async throws {
        log.trace("Sending binary message")
        await withCheckedContinuation { continuation in
            webSocket.write(data: data, completion: continuation.resume)
        }
    }
}
#endif
