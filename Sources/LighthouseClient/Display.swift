import Foundation

/// An 'image' to be displayed on the lighthouse.
public struct Display: Hashable, Encodable {
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

    public func encode(to encoder: Encoder) throws {
        let data = Data(pixels.flatMap { [$0.red, $0.green, $0.blue] })
        try data.encode(to: encoder)
    }
}
