/// A connection to the lighthouse server.
public struct Connection {
    private let authentication: Authentication

    public init(authentication: Authentication) {
        self.authentication = authentication
    }
}
