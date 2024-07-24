#if canImport(Starscream)
import Foundation
import Logging
import Starscream

private let log = Logger(label: "LighthouseWebSocket.StarscreamWebSocket")

public final actor _StarscreamWebSocket: WebSocketProtocol, Starscream.WebSocketDelegate {
    private var webSocket: Starscream.WebSocket
    private var connectHandlers: [(Result<Void, any Error>) -> Void] = []
    private var binaryMessageHandlers: [(Data) -> Void] = []
    private var isSending: Bool = false
    
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
        // We have to serialize all message sends, for which we need
        // a flag (actor isolation is not sufficient to due reentrancy).
        while isSending {
            try await Task.sleep(for: .milliseconds(2))
        }

        isSending = true
        log.trace("Sending binary message")
        await withCheckedContinuation { continuation in
            webSocket.write(data: data, completion: continuation.resume)
        }
        isSending = false
    }
}
#endif
