public enum Protocol {
    public struct ClientMessage: Codable {
        public enum CodingKeys: String, CodingKey {
            case requestId = "REID"
            case verb = "VERB"
            case path = "PATH"
            case meta = "META"
            case authentication = "AUTH"
            // TODO
            // case payload = "PAYL"
        }

        public var requestId: Int
        public var verb: String
        public var path: [String]
        public var meta: [String: String] = [:]
        public var authentication: Authentication
        // TODO
        // public let payload: Payload
    }

    // TODO: Add server messages and payloads
}
