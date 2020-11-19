// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cbeacon",
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", .exact( "0.4.0")),
    ],
    targets: [
        .target(
            name: "cbeacon",
            dependencies: ["SPMUtility"]),
    ]
)
