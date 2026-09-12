// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "dual_screen_hinge",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "dual-screen-hinge", targets: ["dual_screen_hinge"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "dual_screen_hinge",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            swiftSettings: [
                .define("DUAL_SCREEN_HINGE_IOS27"),
            ]
        ),
        .testTarget(
            name: "dual_screen_hingeTests",
            dependencies: ["dual_screen_hinge"],
            path: "Tests"
        )
    ]
)
