// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NomNomDesignSystem",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "NomNomDesignSystem",
            targets: ["NomNomDesignSystem"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NomNomDesignSystem",
            dependencies: [],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "NomNomDesignSystemTests",
            dependencies: ["NomNomDesignSystem"]
        ),
    ]
)
