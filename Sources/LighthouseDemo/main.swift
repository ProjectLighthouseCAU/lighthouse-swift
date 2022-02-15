import Dispatch
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
    print("Connected to the lighthouse")

    while true {
        print("Sending display")
        try await conn.send(display: Display(fill: .green))
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

Task {
    try! await main()
}

dispatchMain()
