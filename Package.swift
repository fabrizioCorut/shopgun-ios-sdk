// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TjekSDK",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "TjekSDK",
            targets: ["TjekSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
//        .package(path: "EventsKit")
    ],
    targets: [
        .target(
            name: "TjekSDK",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "TjekSDKTests",
            dependencies: ["TjekSDK"],
            path: "Tests"
        ),
    ]
)
