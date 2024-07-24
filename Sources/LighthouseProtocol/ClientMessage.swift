/// A message originating from the lighthouse client.
public struct ClientMessage<Payload> {
    public enum CodingKeys: String, CodingKey {
        case requestId = "REID"
        case verb = "VERB"
        case path = "PATH"
        case meta = "META"
        case authentication = "AUTH"
        case payload = "PAYL"
    }

    public var requestId: Int
    public var verb: Verb
    public var path: [String]
    public var meta: [String: String]
    public var authentication: Authentication
    public var payload: Payload

    public init(
        requestId: Int,
        verb: Verb,
        path: [String],
        meta: [String: String] = [:],
        authentication: Authentication,
        payload: Payload
    ) {
        self.requestId = requestId
        self.verb = verb
        self.path = path
        self.meta = meta
        self.authentication = authentication
        self.payload = payload
    }
}

extension ClientMessage where Payload == () {
    public init(
        requestId: Int,
        verb: Verb,
        path: [String],
        meta: [String: String] = [:],
        authentication: Authentication
    ) {
        self.init(
            requestId: requestId,
            verb: verb,
            path: path,
            meta: meta,
            authentication: authentication,
            payload: ()
        )
    }
}

extension ClientMessage: Equatable where Payload: Equatable {}
extension ClientMessage: Hashable where Payload: Hashable {}
extension ClientMessage: Encodable where Payload: Encodable {}
extension ClientMessage: Decodable where Payload: Decodable {}
