// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TVCore",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TVCore",
            targets: ["TVCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/odyshewroman/AndroidTVRemoteControl", exact: "2.4.16"),
        .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", exact: "7.6.5"),
        .package(url: "https://github.com/daltoniam/Starscream", from: "4.0.6")
    ],
    targets: [
        .target(
            name: "TVCore",
            dependencies: [
                "AndroidTVRemoteControl",
                "CocoaAsyncSocket",
                "Starscream"
            ],
            path: "Sources", // Path to your framework's source code
            resources: [
                .process("TVCore/Assets/Assets.xcassets") // Add any resources, if necessary
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
