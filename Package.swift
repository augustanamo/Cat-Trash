// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CatTrash",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CatTrash", targets: ["CatTrash"])
    ],
    targets: [
        .executableTarget(
            name: "CatTrash",
            path: "Sources/CatTrash",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("ApplicationServices")
            ]
        )
    ]
)
