/// The payload of a `LIST` request.
public struct DirectoryTree: Hashable, RawRepresentable {
    /// The entries in the directory.
    public var rawValue: [String: Entry]

    /// The number of entries in the directory.
    public var count: Int {
        rawValue.count
    }

    /// Creates a directory tree from the given entries.
    public init(rawValue: [String: Entry] = [:]) {
        self.rawValue = rawValue
    }

    /// Creates a directory tree from the given entries.
    public init(_ rawValue: [String: Entry]) {
        self.init(rawValue: rawValue)
    }

    /// Accesses the child entry with the given name.
    public subscript(_ name: String) -> Entry? {
        get { rawValue[name] }
        set { rawValue[name] = newValue }
    }
}

extension DirectoryTree {
    /// An entry in the directory. Either a resource or a directory tree.
    public enum Entry: Codable, Hashable, CustomStringConvertible, ExpressibleByDictionaryLiteral {
        case resource
        case directory(DirectoryTree)

        public var description: String {
            switch self {
            case .resource: ".resource"
            case .directory(let tree): String(describing: tree)
            }
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .resource
            } else {
                let tree = try container.decode(DirectoryTree.self)
                self = .directory(tree)
            }
        }

        public init(dictionaryLiteral elements: (String, Entry)...) {
            self = .directory(DirectoryTree(Dictionary(uniqueKeysWithValues: elements)))
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()

            switch self {
            case .resource:
                try container.encodeNil()
            case .directory(let tree):
                try container.encode(tree)
            }
        }
    }
}

extension DirectoryTree: CustomStringConvertible {
    public var description: String {
        String(describing: rawValue)
    }
}

extension DirectoryTree: Decodable {
    public init(from decoder: any Decoder) throws {
        self.init(rawValue: try .init(from: decoder))
    }
}

extension DirectoryTree: Encodable {
    public func encode(to encoder: any Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

extension DirectoryTree: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Entry)...) {
        self.init(rawValue: Dictionary(uniqueKeysWithValues: elements))
    }
}

extension DirectoryTree: Sequence {
    public func makeIterator() -> Dictionary<String, Entry>.Iterator {
        rawValue.makeIterator()
    }
}
