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
        .library(
            name: "HTMLRenderer",
            targets: ["HTMLRenderer"]
        ),
    ],
    dependencies: [],
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
        .target(
            name: "HTMLRenderer",
            dependencies: ["HTMLParser"]
        ),
        .testTarget(
            name: "HTMLParserTests",
            dependencies: ["HTMLParser"]
        ),
        .testTarget(
            name: "HTMLRendererTests",
            dependencies: ["HTMLRenderer"]
        ),
    ]
)
