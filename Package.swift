// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-html-renderer",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "HTMLParser",
            targets: ["HTMLParser"]
        ),
    ],
    targets: [
        .target(
            name: "CGumbo",
            path: "Sources/CGumbo",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("src"),
            ]
        ),
        .target(
            name: "HTMLParser",
            dependencies: ["CGumbo"]
        ),
        .testTarget(
            name: "HTMLParserTests",
            dependencies: ["HTMLParser"]
        ),
        .executableTarget(
            name: "HTMLParserBenchmarks",
            dependencies: ["HTMLParser"],
            path: "Benchmarks/HTMLParserBenchmarks"
        ),
    ]
)
