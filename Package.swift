// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ReflowClip",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ReflowClip",
            path: "Sources/ReflowClip"
        )
    ]
)
