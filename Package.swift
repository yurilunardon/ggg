// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HandyShots",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "HandyShots",
            targets: ["HandyShots"]
        )
    ],
    dependencies: [
        // Lottie for TGS animation support
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.3.0")
    ],
    targets: [
        .executableTarget(
            name: "HandyShots",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "HandyShots",
            exclude: [
                "Resources/Info.plist",
                "Resources/HandyShots.entitlements",
                "Resources/Animations/README.md"
            ],
            resources: [
                .process("Resources/Animations")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)
