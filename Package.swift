// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "NStack",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "NStack", targets: ["NStack"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.43.0"),
    ],
    targets: [
        .target(
            name: "NStack",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "NStackTests",
            dependencies: [
                "NStack",
                .product(name: "XCTVapor", package: "vapor")
            ]
        ),
    ]
)
