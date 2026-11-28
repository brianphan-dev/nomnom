// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NomNomCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "NomNomCore",
            targets: ["NomNomCore"]
        ),
    ],
    dependencies: [
        .package(path: "../NomNomShared"),
    ],
    targets: [
        .target(
            name: "NomNomCore",
            dependencies: [
                .product(name: "NomNomShared", package: "NomNomShared"),
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3"),
            ]
        ),
        .testTarget(
            name: "NomNomCoreTests",
            dependencies: [
                "NomNomCore",
                .product(name: "NomNomShared", package: "NomNomShared"),
            ]
        ),
    ]
)
