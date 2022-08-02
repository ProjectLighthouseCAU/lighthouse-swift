# Project Lighthouse Client for Swift

[![Build](https://github.com/fwcd/lighthouse-swift/actions/workflows/build.yml/badge.svg)](https://github.com/fwcd/lighthouse-swift/actions/workflows/build.yml)

An API client for a light installation at the University of Kiel using Swift 5.5's async/await. Runs on both Linux and macOS.

## Example

```swift
// Prepare connection
let conn = Connection(authentication: Authentication(
    username: "[your username]",
    token: "[your token]"
))

// Handle incoming input events
conn.onInput { input in
    print("Got input \(input)")
}

// Connect to the lighthouse server and request events
try await conn.connect()
try await conn.requestStream()

// Repeatedly send colored displays to the lighthouse
while true {
    try await conn.send(display: Display(fill: .random()))
    try await Task.sleep(nanoseconds: 1_000_000_000)
}
```

For more details, check out the [`LighthouseDemo` source code](Sources/LighthouseDemo/LighthouseDemo.swift).

## Usage

First make sure to have a login at [lighthouse.uni-kiel.de](https://lighthouse.uni-kiel.de) and to have your credentials defined as environment variables:

```bash
export LIGHTHOUSE_USERNAME=[your username]
export LIGHTHOUSE_TOKEN=[your api token]
```

Running the example is now as easy as invoking

```bash
swift run LighthouseDemo
```
