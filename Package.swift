// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReCombine",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(name: "ReCombine", targets: ["ReCombine"]),
        .library(name: "ReCombineTest", targets: ["ReCombineTest"]),
    ],
    targets: [
        .target(name: "ReCombine", dependencies: []),
        .testTarget(name: "ReCombineTests", dependencies: ["ReCombine"]),
        .target(name: "ReCombineTest", dependencies: ["ReCombine"]),
        .testTarget(name: "ReCombineTestTests", dependencies: ["ReCombine", "ReCombineTest"]),
    ]
)
