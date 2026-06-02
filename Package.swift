// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Runkun",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Runkun", targets: ["Runkun"])
    ],
    targets: [
        .executableTarget(
            name: "Runkun",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit")
            ]
        )
    ]
)
