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

    public init(
        source: Int,
        key: Int? = nil,
        button: Int? = nil,
        isDown: Bool
    ) {
        self.source = source
        self.key = key
        self.button = button
        self.isDown = isDown
    }
}
