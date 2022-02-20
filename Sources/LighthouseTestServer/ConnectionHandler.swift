import NIO
import MessagePack
import Vapor
import LighthouseProtocol

private let log = Logger(label: "LighthouseTestServer.MessagingHandler")

/// Handles the server side of the LighthouseTestServer's web sockets.
class ConnectionHandler {
    private var clients: [UUID: ClientState] = [:]

    private class ClientState {
        private let ws: WebSocket
        var receivesStream: Bool = false
        var display: Display = .init()
        var name: String? = nil

        init(ws: WebSocket) {
            self.ws = ws
        }

        func respond(to requestId: Int, code: Int, response: String? = nil) throws {
            log.info("Responding with \(code) (id: \(requestId))")
            try send(message: Protocol.ServerMessage(
                code: code,
                requestId: requestId,
                response: response
            ))
        }

        func send<Message>(message: Message) throws where Message: Encodable {
            let data = try MessagePackEncoder().encode(message)
            send(data: data)
        }

        func send(data: Data) {
            ws.send(Array(data))
        }
    }

    func connect(_ ws: WebSocket) {
        let uuid = UUID()
        clients[uuid] = ClientState(ws: ws)
        log.info("Opened connection to \(uuid)")

        ws.onBinary { [weak self] _, buf in
            guard let data = buf.getData(at: 0, length: buf.readableBytes) else {
                log.warning("Could not read data from WebSocket")
                return
            }
            self?.handleReceive(of: data, for: uuid)
        }

        ws.onClose.whenComplete { [weak self] _ in
            self?.clients[uuid] = nil
            log.info("Closed connection to \(uuid)")
        }
    }

    func handleReceive(of data: Data, for uuid: UUID) {
        do {
            guard let client = clients[uuid] else {
                log.warning("No client associated with \(uuid)")
                return
            }

            let message = try MessagePackDecoder().decode(Protocol.ClientMessage.self, from: data)
            log.info("Got \(message.verb) \(message.path.joined(separator: "/")) (id: \(message.requestId))")

            let name = message.authentication.username
            client.name = name

            switch message.verb {
            case "PUT":
                log.info("Got a PUT, forwarding it to others")
                // TODO
            case "STREAM":
                client.receivesStream = true
                log.info("Enabled stream for \(name)")
                try client.respond(to: message.requestId, code: 200)
            default:
                log.warning("Got unknown verb '\(message.verb)'")
                try client.respond(to: message.requestId, code: 400, response: "Bad Request")
                break
            }
        } catch {
            log.warning("Error while handling message: \(error)")
        }
    }
}
