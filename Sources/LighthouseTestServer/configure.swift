import Vapor
import Leaf

public func configure(_ app: Application) throws {
    // Serve from /Public
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.views.use(.leaf)

    // Register routes
    try routes(app)
}
