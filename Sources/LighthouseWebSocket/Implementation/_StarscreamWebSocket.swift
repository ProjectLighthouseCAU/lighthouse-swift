#if canImport(Starscream)
import Foundation
import Logging
import Starscream

private let log = Logger(label: "LighthouseWebSocket.StarscreamWebSocket")

public final actor _StarscreamWebSocket: WebSocketProtocol, Starscream.WebSocketDelegate {
    private var webSocket: Starscream.WebSocket
    private var connectHandlers: [(Result<Void, any Error>) -> Void] = []
    private var binaryMessageHandlers: [(Data) -> Void] = []
    private var isConnected: Bool = false
    
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
        isConnected = true
    }
    
    public func onBinary(_ handler: @escaping (Data) -> Void) throws {
        log.trace("Adding binary message handler")
        binaryMessageHandlers.append(handler)
    }
    
    public nonisolated func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        Task {
            await handle(event: event)
        }
    }

    private func handle(event: WebSocketEvent) {
        log.trace("Handling WebSocketEvent \(event)")
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
        guard isConnected else { throw WebSocketError.notConnectedYet }

        log.trace("Sending binary message")
        await withCheckedContinuation { continuation in
            webSocket.write(data: data, completion: continuation.resume)
        }
    }
}
#endif
