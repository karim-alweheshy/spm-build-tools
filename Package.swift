// swift-tools-version:5.6

import Foundation
import PackageDescription

let package = Package(
    name: "BuildSystemPlugin",
    products: [
        .library(name: "Example", targets: ["Example"]),
        .plugin(name: "BuildSystemPlugin", targets: ["BuildSystemPlugin"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Example",
            plugins: [.plugin(name: "BuildSystemPlugin")]
        ),
        .plugin(
            name: "BuildSystemPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "swiftlint"),
                .target(name: "swiftgen"),
                .target(name: "sourcery")
            ]
        ),
        .binaryTarget(
            name: "swiftlint",
            path: "Binaries/swiftlint.artifactbundle"
        ),
        .binaryTarget(
            name: "swiftgen",
            path: "Binaries/swiftgen.artifactbundle"
        ),
        .binaryTarget(
            name: "sourcery",
            path: "Binaries/sourcery.artifactbundle"
        )
    ]
)
