/// An empty payload.
///
/// Can be decoded from anything and is encoded as `nil`.
public struct Nil: Codable, Hashable {
    public init() {}

    public init(from decoder: any Decoder) throws {
        // Decode anything
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
