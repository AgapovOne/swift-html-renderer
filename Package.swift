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
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.6"),
        .package(url: "https://github.com/kylehowells/swift-justhtml.git", from: "0.3.3"),
        .package(url: "https://github.com/Rightpoint/BonMot.git", from: "6.1.3"),
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
            name: "CLexbor",
            path: "Sources/CLexbor",
            publicHeadersPath: ".",
            cSettings: [
                .define("LEXBOR_STATIC"),
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
        .executableTarget(
            name: "HTMLParserBenchmarks",
            dependencies: [
                "HTMLParser",
                "HTMLRenderer",
                "CLexbor",
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "justhtml", package: "swift-justhtml"),
                .product(name: "BonMot", package: "BonMot"),
            ],
            path: "Benchmarks/HTMLParserBenchmarks"
        ),
    ]
)
