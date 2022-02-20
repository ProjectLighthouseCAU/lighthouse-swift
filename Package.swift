// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "lighthouse-swift",
    platforms: [.macOS("10.15")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LighthouseClient",
            targets: ["LighthouseProtocol", "LighthouseClient"]
        ),
        .executable(
            name: "LighthouseDemo",
            targets: ["LighthouseDemo"]
        ),
        .executable(
            name: "LighthouseTestServer",
            targets: ["LighthouseTestServer"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.3.0"),
        .package(url: "https://github.com/Flight-School/MessagePack.git", from: "1.2.4"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.3"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LighthouseProtocol",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "LighthouseClient",
            dependencies: [
                .target(name: "LighthouseProtocol"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "MessagePack", package: "MessagePack"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
            ]
        ),
        .executableTarget(
            name: "LighthouseDemo",
            dependencies: [
                .target(name: "LighthouseProtocol"),
                .target(name: "LighthouseClient"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .executableTarget(
            name: "LighthouseTestServer",
            dependencies: [
                .target(name: "LighthouseProtocol"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "MessagePack", package: "MessagePack"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Leaf", package: "leaf"),
            ]
        ),
        // .testTarget(
        //     name: "LighthouseClientTests",
        //     dependencies: [
        //         .target(name: "LighthouseClient"),
        //     ]
        // ),
    ]
)
