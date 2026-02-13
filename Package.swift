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
        .library(
            name: "CLexbor",
            targets: ["CLexbor"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CLexbor",
            path: "Sources/CLexbor",
            publicHeadersPath: ".",
            cSettings: [
                .define("LEXBOR_STATIC"),
            ]
        ),
        .target(
            name: "HTMLParser",
            dependencies: ["CLexbor"]
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
