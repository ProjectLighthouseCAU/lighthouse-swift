/// The protocol structures for communication with the lighthouse API.
public enum Protocol {
    /// A message payload.
    public enum Payload: Codable {
        case display(Display)
        case other

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let display = try? container.decode(Display.self) {
                self = .display(display)
            } else {
                self = .other
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
                case .display(let display): try container.encode(display)
                case .other: break
            }
        }
    }

    /// A message originating from the lighthouse client.
    public struct ClientMessage: Codable {
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

    /// A message originating from the lighthouse server.
    public struct ServerMessage: Codable {
        public enum CodingKeys: String, CodingKey {
            case code = "RNUM"
            case requestId = "REID"
            case warnings = "WARNINGS"
            case response = "RESPONSE"
            case payload = "PAYL"
        }

        public var code: Int
        public var requestId: Int
        public var warnings: [String]?
        public var response: String?
        public var payload: Payload
    }
}
