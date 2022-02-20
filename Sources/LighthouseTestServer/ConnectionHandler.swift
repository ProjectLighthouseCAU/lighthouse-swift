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
        var name: String? = nil

        init(ws: WebSocket) {
            self.ws = ws
        }

        func handleReceive(of data: Data) {
            do {
                let message = try MessagePackDecoder().decode(Protocol.ClientMessage.self, from: data)

                log.info("Got \(message)")
                // TODO: Handle it
            } catch {
                log.warning("Error while decoding message: \(error)")
            }
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
            self?.clients[uuid]?.handleReceive(of: data)
        }

        ws.onClose.whenComplete { [weak self] _ in
            self?.clients[uuid] = nil
            log.info("Closed connection to \(uuid)")
        }
    }
}
