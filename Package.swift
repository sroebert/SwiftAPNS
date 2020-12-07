// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftAPNS",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "apns", targets: ["SwiftAPNS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.1"),
    ],
    targets: [
        .target(name: "SwiftAPNS", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
    ]
)
