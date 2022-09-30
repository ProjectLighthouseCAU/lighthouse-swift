import ArgumentParser
import Dispatch
import Foundation
import Logging
import LighthouseClient

private let log = Logger(label: "LighthouseDemo")
private let env = ProcessInfo.processInfo.environment

@main
struct LighthouseDemo: ParsableCommand {
    @Option(name: .shortAndLong, help: "The username for authentication")
    var username: String = env["LIGHTHOUSE_USER"] ?? ""

    @Option(name: .shortAndLong, help: "The API token for authentication")
    var token: String = env["LIGHTHOUSE_TOKEN"] ?? ""

    @Option(help: "The URL for the lighthouse server")
    var url: URL = lighthouseUrl

    func runAsync() async throws {
        guard !username.isEmpty else { fatalError("Missing username!") }
        guard !token.isEmpty else { fatalError("Missing token!") }

        // Prepare connection
        let auth = Authentication(username: username, token: token)
        let lh = Lighthouse(authentication: auth, url: url)

        // Handle incoming input events
        lh.onInput { input in
            log.info("Got input \(input)")
        }

        // Connect to the lighthouse server
        try await lh.connect()
        log.info("Connected to the lighthouse")

        // Request a stream of events
        try await lh.requestStream()

        // Repeatedly send colored displays (frames) to the lighthouse
        while true {
            log.info("Sending display")
            try await lh.send(display: Display(fill: .random()))
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    func run() {
        let task = Task {
            try await withTaskCancellationHandler {
                try await runAsync()
            } onCancel: {
                log.info("Cancelled")
            }
        }

        // Register interrupt (ctrl-c) handler
        let source = DispatchSource.makeSignalSource(signal: SIGINT)
        source.setEventHandler {
            task.cancel()
            Self.exit()
        }
        source.resume()

        dispatchMain()
    }
}
