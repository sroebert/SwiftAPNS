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
        .package(url: "https://github.com/vapor/console-kit.git", from: "4.2.0"),
    ],
    targets: [
        .target(name: "SwiftAPNS", dependencies: [
            .product(name: "ConsoleKit", package: "console-kit"),
        ]),
    ]
)
