// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NomNomShared",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "NomNomShared",
            targets: ["NomNomShared"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NomNomShared",
            dependencies: []
        ),
        .testTarget(
            name: "NomNomSharedTests",
            dependencies: ["NomNomShared"]
        ),
    ]
)
