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
