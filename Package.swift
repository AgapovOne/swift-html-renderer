// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-html-renderer",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HTMLRenderer", targets: ["HTMLRenderer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AgapovOne/swift-lexbor", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "HTMLRenderer",
            dependencies: [
                .product(name: "HTMLParser", package: "swift-lexbor"),
            ]
        ),
        .testTarget(
            name: "HTMLRendererTests",
            dependencies: ["HTMLRenderer"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
