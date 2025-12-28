// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Sight",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Sight", targets: ["Sight"])
    ],
    targets: [
        .executableTarget(
            name: "Sight",
            path: "Sources/Sight",
            resources: [
                .copy("Resources"),
                .copy("Overlay/Shaders")
            ]
        ),
        .testTarget(
            name: "SightTests",
            dependencies: ["Sight"],
            path: "Tests/SightTests"
        )
    ]
)
