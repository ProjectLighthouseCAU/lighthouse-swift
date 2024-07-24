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
