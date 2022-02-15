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
    let conn = Connection(authentication: auth)

    // Handle incoming messages
    conn.onMessage { message in
        print("Got \(message)")
    }

    // Handle incoming input events
    conn.onInput { input in
        print("Got input \(input)")
    }

    // Connect to the lighthouse server
    try await conn.connect()
    print("Connected to the lighthouse")

    // Request a stream of input events
    // TODO: Debug requestStream
    // try await conn.requestStream()

    // Repeatedly send colored displays (frames) to the lighthouse
    while true {
        print("Sending display")
        try await conn.send(display: Display(fill: .random()))
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

Task {
    try! await main()
}

dispatchMain()
