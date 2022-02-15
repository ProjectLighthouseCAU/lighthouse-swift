import Foundation

/// An 'image' to be displayed on the lighthouse.
public struct Display: Hashable, Codable {
    /// The pixels in row-major order.
    public var pixels: [Color] {
        didSet {
            assert(pixels.count == lighthouseSize)
        }
    }

    public init(pixels: [Color]) {
        assert(pixels.count == lighthouseSize)
        self.pixels = pixels
    }

    public init(fill color: Color) {
        self.init(pixels: Array(repeating: color, count: lighthouseSize))
    }

    public init() {
        self.init(fill: .black)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        assert(data.count % 3 == 0)

        var pixels: [Color] = []
        for i in 0..<(data.count / 3) {
            pixels.append(Color(
                red: data[i * 3],
                green: data[i * 3 + 1],
                blue: data[i * 3 + 2]
            ))
        }

        self.pixels = pixels
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = Data(pixels.flatMap { [$0.red, $0.green, $0.blue] })
        try container.encode(data)
    }
}
