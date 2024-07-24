#if canImport(WebSocketKit)

public typealias WebSocket = _WebSocketKitWebSocket

#elseif canImport(Starscream)

public typealias WebSocket = _StarscreamWebSocket

#else
#error("No WebSocket implementation available!")
#endif
