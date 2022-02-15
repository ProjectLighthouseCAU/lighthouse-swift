/// An 'image' to be displayed on the lighthouse.
public struct Display: Hashable {
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
}
