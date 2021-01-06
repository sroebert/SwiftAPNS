// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "APNS",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "apns", targets: ["APNS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.1"),
    ],
    targets: [
        .target(name: "APNS", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
    ]
)
