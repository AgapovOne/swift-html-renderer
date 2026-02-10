// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-html-renderer",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "swift-html-renderer",
            targets: ["swift-html-renderer"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "swift-html-renderer"
        ),
        .testTarget(
            name: "swift-html-rendererTests",
            dependencies: ["swift-html-renderer"]
        ),
    ]
)
