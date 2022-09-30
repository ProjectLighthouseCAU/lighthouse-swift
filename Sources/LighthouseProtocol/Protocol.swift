/// A key/controller input event from the web interface.
public struct InputEvent: Codable {
    public enum CodingKeys: String, CodingKey {
        case source = "src"
        case key
        case button = "btn"
        case isDown = "dwn"
    }

    public var source: Int
    public var key: Int?
    public var button: Int?
    public var isDown: Bool
}

/// A message payload.
public enum Payload: Codable {
    case inputEvent(InputEvent)
    case frame(Frame)
    case other

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let inputEvent = try? container.decode(InputEvent.self) {
            self = .inputEvent(inputEvent)
        } else if let frame = try? container.decode(Frame.self) {
            self = .frame(frame)
        } else {
            self = .other
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case .frame(let frame): try container.encode(frame)
            case .inputEvent(let inputEvent): try container.encode(inputEvent)
            case .other: try container.encodeNil()
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
    public var meta: [String: String]
    public var authentication: Authentication
    public var payload: Payload

    public init(
        requestId: Int,
        verb: String,
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

/// An error originating from the server.
public enum ServerError: Error, Hashable {
    case serverError(code: Int, message: String?)
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

    public init(
        code: Int,
        requestId: Int,
        warnings: [String]? = nil,
        response: String? = nil,
        payload: Payload = .other
    ) {
        self.code = code
        self.requestId = requestId
        self.warnings = warnings
        self.response = response
        self.payload = payload
    }

    /// Checks this response and returns only if successful.
    public func check() throws {
        if code != 200 {
            throw ServerError.serverError(code: code, message: response)
        }
    }
}
