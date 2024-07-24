#if canImport(Starscream)
import Foundation
import Starscream

public final class _StarscreamWebSocket: WebSocketProtocol, Starscream.WebSocketDelegate {
    private var webSocket: Starscream.WebSocket
    private var connectHandlers: [(Result<Void, any Error>) -> Void] = []
    private var binaryMessageHandlers: [(Data) -> Void] = []
    
    public init(url: URL) {
        webSocket = Starscream.WebSocket(request: URLRequest(url: url))
        webSocket.delegate = self
    }
    
    public func connect() async throws {
        try await withCheckedThrowingContinuation { continuation in
            connectHandlers.append(continuation.resume(with:))
            webSocket.connect()
        }
    }
    
    public func onBinary(_ handler: @escaping (Data) -> Void) throws {
        binaryMessageHandlers.append(handler)
    }
    
    public func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        switch event {
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
        await withCheckedContinuation { continuation in
            webSocket.write(data: data, completion: continuation.resume)
        }
    }
}
#endif
