import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        req.view.render("index")
    }

    let handler = ConnectionHandler()
    app.webSocket("websocket") { req, ws in
        handler.connect(ws)
    }
}
