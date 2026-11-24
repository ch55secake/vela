// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Vela",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "Vela", targets: ["Vela"]),
        .library(name: "VelaCore", targets: ["VelaCore"]),
    ],
    targets: [
        .target(name: "VelaCore"),
        .executableTarget(
            name: "Vela",
            dependencies: ["VelaCore"]
        ),
        .testTarget(
            name: "VelaCoreTests",
            dependencies: ["VelaCore"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
