// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenTracker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "OpenTracker", targets: ["OpenTracker"])
    ],
    targets: [
        .executableTarget(
            name: "OpenTracker"
        )
    ]
)
