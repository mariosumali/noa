// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "noa",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "noa", targets: ["noa"])
    ],
    targets: [
        .executableTarget(
            name: "noa",
            path: "noa"
        )
    ]
)
