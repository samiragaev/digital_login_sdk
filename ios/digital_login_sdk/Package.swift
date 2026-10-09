// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "digital_login_sdk",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "digital-login-sdk", targets: ["digital_login_sdk"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "digital_login_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
