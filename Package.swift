// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "WolfImage",
    platforms: [
        .iOS(.v9), .macOS(.v10_13), .tvOS(.v11)
    ],
    products: [
        .library(
            name: "WolfImage",
            type: .dynamic,
            targets: ["WolfImage"]),
        ],
    dependencies: [
        .package(url: "https://github.com/wolfmcnally/WolfCore", from: "5.0.0"),
        .package(url: "https://github.com/wolfmcnally/WolfColor", from: "4.0.0"),
        .package(url: "https://github.com/wolfmcnally/WolfGeometry", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "WolfImage",
            dependencies: ["WolfCore", "WolfColor", "WolfGeometry"])
        ]
)
