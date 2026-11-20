// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Lumina",
    defaultLocalization: "id",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Lumina",
            targets: ["Lumina"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Lumina",
            dependencies: [],
            path: ".",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "LuminaTests",
            dependencies: ["Lumina"],
            path: "Tests"
        )
    ]
)
