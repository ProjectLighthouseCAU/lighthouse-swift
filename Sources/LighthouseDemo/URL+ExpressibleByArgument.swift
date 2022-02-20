import ArgumentParser
import Foundation

// Workaround for https://github.com/apple/swift-argument-parser/issues/82

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(string: argument)
    }
}
