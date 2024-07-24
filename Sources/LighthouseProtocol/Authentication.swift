/// The credentials used to authenticate with the lighthouse.
public struct Authentication: Codable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case username = "USER"
        case token = "TOKEN"
    }

    public let username: String
    public let token: String

    public init(username: String, token: String) {
        self.username = username
        self.token = token
    }
}
