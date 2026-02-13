// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HTMLParserBenchmarks",
    platforms: [.iOS(.v17), .macOS(.v14)],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.6"),
        .package(url: "https://github.com/kylehowells/swift-justhtml.git", from: "0.3.3"),
        .package(url: "https://github.com/Rightpoint/BonMot.git", from: "6.1.3"),
    ],
    targets: [
        .target(
            name: "CLexbor",
            path: "Sources/CLexbor",
            publicHeadersPath: ".",
            cSettings: [
                .define("LEXBOR_STATIC"),
            ]
        ),
        .executableTarget(
            name: "HTMLParserBenchmarks",
            dependencies: [
                .product(name: "HTMLParser", package: "swift-html-renderer"),
                .product(name: "HTMLRenderer", package: "swift-html-renderer"),
                "CLexbor",
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "justhtml", package: "swift-justhtml"),
                .product(name: "BonMot", package: "BonMot"),
            ],
            path: "HTMLParserBenchmarks"
        ),
    ]
)
