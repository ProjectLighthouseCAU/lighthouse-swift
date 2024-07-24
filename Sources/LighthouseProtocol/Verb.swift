/// A request method.
public struct Verb: RawRepresentable, Hashable, Codable {
    /// The `POST` method.
    ///
    /// This method creates and updates a resource.
    public static let post = Self(rawValue: "POST")
    /// The `CREATE` method.
    ///
    /// This method creates a resource.
    public static let create = Self(rawValue: "CREATE")
    /// The `MKDIR` method.
    ///
    /// This method creates a directory.
    public static let mkdir = Self(rawValue: "MKDIR")
    /// The `DELETE` method.
    ///
    /// This method deletes a resource.
    public static let delete = Self(rawValue: "DELETE")
    /// The `LIST` method.
    ///
    /// This method lists the contents of a directory.
    public static let list = Self(rawValue: "LIST")
    /// The `GET` method.
    ///
    /// This method fetchs a resource.
    public static let get = Self(rawValue: "GET")
    /// The `PUT` method.
    ///
    /// This method updates a resource.
    public static let put = Self(rawValue: "PUT")
    /// The `STREAM` method.
    ///
    /// This method opens a stream to a resource.
    public static let stream = Self(rawValue: "STREAM")
    /// The `STOP` method.
    ///
    /// This method stops a stream to a resource.
    public static let stop = Self(rawValue: "STOP")
    /// The `LINK` method.
    ///
    /// This method creates a link between resources.
    public static let link = Self(rawValue: "LINK")
    /// The `UNLINK` method.
    ///
    /// This method removes a link between resources.
    public static let unlink = Self(rawValue: "UNLINK")

    /// The raw name of the method. Must generally be uppercase.
    public let rawValue: String

    /// Creates a new verb from the given raw method name.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension Verb: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}
