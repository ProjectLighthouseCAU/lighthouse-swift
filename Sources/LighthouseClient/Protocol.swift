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

    // TODO: Add server messages and payloads
}
