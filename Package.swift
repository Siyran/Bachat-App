// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Bachat",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Bachat", targets: ["Bachat"])
    ],
    targets: [
        .executableTarget(
            name: "Bachat",
            path: "Bachat"
        ),
        .testTarget(
            name: "BachatTests",
            dependencies: ["Bachat"],
            path: "BachatTests"
        )
    ]
)
