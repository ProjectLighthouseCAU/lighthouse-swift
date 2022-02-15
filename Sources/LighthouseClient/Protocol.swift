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

        public let requestId: Int
        public let verb: String
        public let path: [String]
        public let meta: [String: String]
        public let authentication: Authentication
        // TODO
        // public let payload: Payload
    }

    // TODO: Add server messages and payloads
}
