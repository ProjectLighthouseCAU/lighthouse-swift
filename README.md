# Project Lighthouse SDK for Swift

[![Build](https://github.com/ProjectLighthouseCAU/lighthouse-swift/actions/workflows/build.yml/badge.svg)](https://github.com/ProjectLighthouseCAU/lighthouse-swift/actions/workflows/build.yml)
[![Docs](https://github.com/ProjectLighthouseCAU/lighthouse-swift/actions/workflows/docs.yml/badge.svg)](https://projectlighthousecau.github.io/lighthouse-swift/documentation/lighthouseclient)

A modern async wrapper around the Project Lighthouse API for Swift, e.g. to build games and other clients. Runs on Linux and Apple platforms (macOS, iOS, ...).

## Example

```swift
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
```

For more details, check out the [`LighthouseDemo` source code](Sources/LighthouseDemo/LighthouseDemo.swift).

## Usage

First make sure to have a login at [lighthouse.uni-kiel.de](https://lighthouse.uni-kiel.de) and to have your credentials defined as environment variables:

```bash
export LIGHTHOUSE_USER=[your username]
export LIGHTHOUSE_TOKEN=[your api token]
```

Running the example is now as easy as invoking

```bash
swift run LighthouseDemo
```
