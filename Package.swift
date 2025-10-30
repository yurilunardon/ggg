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
        // No external dependencies for MVP
    ],
    targets: [
        .executableTarget(
            name: "HandyShots",
            path: "HandyShots",
            exclude: [
                "Resources/Info.plist",
                "Resources/HandyShots.entitlements"
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)
