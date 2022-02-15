public enum Protocol {
    // TODO: Make payload decodable

    public enum Payload: Encodable {
        case display(Display)

        public func encode(to encoder: Encoder) throws {
            switch self {
                case .display(let display): try display.encode(to: encoder)
            }
        }
    }

    public struct ClientMessage: Encodable {
        public enum CodingKeys: String, CodingKey {
            case requestId = "REID"
            case verb = "VERB"
            case path = "PATH"
            case meta = "META"
            case authentication = "AUTH"
            case payload = "PAYL"
        }

        public var requestId: Int
        public var verb: String
        public var path: [String]
        public var meta: [String: String] = [:]
        public var authentication: Authentication
        public let payload: Payload
    }

    public struct ServerMessage: Decodable {
        public enum CodingKeys: String, CodingKey {
            case code = "RNUM"
            case requestId = "REID"
            case warnings = "WARNINGS"
            case response = "RESPONSE"
            // TODO: Add payload
            // case payload = "PAYLOAD"
        }

        public var code: Int
        public var requestId: Int
        public var warnings: [String]?
        public var response: String?
        // TODO: Add payload (and handle unknown cases)
        // public var payload: Payload
    }
}
