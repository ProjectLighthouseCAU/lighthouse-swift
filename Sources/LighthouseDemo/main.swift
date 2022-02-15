import Foundation
import LighthouseClient

// Fetch credentials from the enviroment
let env = ProcessInfo.processInfo.environment
let auth = Authentication(
    username: env["LIGHTHOUSE_USERNAME"]!,
    token: env["LIGHTHOUSE_TOKEN"]!
)

func main() async throws {
    // Connect to the lighthouse server
    let conn = Connection(authentication: auth)
    try await conn.connect()
}

Task {
    try! await main()
}
