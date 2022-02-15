import Dispatch
import Foundation
import Logging
import LighthouseClient

let log = Logger(label: "LighthouseDemo")

// Fetch credentials from the enviroment
let env = ProcessInfo.processInfo.environment
let auth = Authentication(
    username: env["LIGHTHOUSE_USERNAME"]!,
    token: env["LIGHTHOUSE_TOKEN"]!
)

func main() async throws {
    let conn = Connection(authentication: auth)

    // Handle incoming input events
    conn.onInput { input in
        log.info("Got input \(input)")
    }

    // Connect to the lighthouse server
    try await conn.connect()
    log.info("Connected to the lighthouse")

    // Request a stream of input events
    try await conn.requestStream()

    // Repeatedly send colored displays (frames) to the lighthouse
    while true {
        log.info("Sending display")
        try await conn.send(display: Display(fill: .random()))
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

Task {
    try! await main()
}

dispatchMain()
