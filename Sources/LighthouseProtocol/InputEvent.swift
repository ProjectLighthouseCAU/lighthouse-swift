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
