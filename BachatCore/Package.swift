// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BachatCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BachatCore", targets: ["BachatCore"])
    ],
    targets: [
        .target(
            name: "BachatCore",
            path: "Sources"
        ),
        .testTarget(
            name: "BachatCoreTests",
            dependencies: ["BachatCore"],
            path: "Tests"
        )
    ]
)
