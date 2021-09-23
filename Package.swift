// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ShopGunSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "ShopGunSDK",
            targets: ["ShopGunSDK"]
        ),
        .library(
            name: "ShopGunSDK-Dynamic",
            type: .dynamic,
            targets: ["ShopGunSDK"]
        )
    ],
    dependencies: [
        .package(name: "Incito", url: "https://github.com/shopgun/incito-ios.git", from: "1.0.3"),
        .package(name: "Future", url: "https://github.com/shopgun/swift-future.git", from: "0.5.0"),
        .package(name: "Verso", url: "https://github.com/shopgun/verso-ios.git", from: "1.0.5"),
        .package(name: "Kingfisher", url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        .package(name: "Valet", url: "https://github.com/square/Valet.git", from: "4.1.1")
    ],
    targets: [
        .target(
            name: "ShopGunSDK",
            dependencies: [
                "Incito",
                "Future",
                "Verso",
                "Kingfisher",
                "Valet"
            ],
            resources: [
                .process("IncitoPublication/Resources/IncitoViewer.graphql"),
                .process("PagedPublication/Resources/")
            ]
        ),
        .testTarget(
            name: "ShopGunSDKTests",
            dependencies: ["ShopGunSDK"]
        )
    ]
)
