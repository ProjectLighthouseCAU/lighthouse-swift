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

        // Connect to the lighthouse server
        try await lh.connect()
        log.info("Connected to the lighthouse")

        // Handle incoming input events
        Task {
            let stream = try await lh.streamModel()
            for await message in stream {
                if case let .inputEvent(input) = message.payload {
                    log.info("Got input \(input)")
                }
            }
        }

        // Repeatedly send colored frames to the lighthouse
        while true {
            log.info("Sending frame")
            try await lh.putModel(frame: Frame(fill: .random()))
            try await Task.sleep(for: .seconds(1))
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
