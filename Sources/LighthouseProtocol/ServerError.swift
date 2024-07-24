/// An error originating from the server.
public enum ServerError: Error, Hashable {
    case serverError(code: Int, message: String?)
}
