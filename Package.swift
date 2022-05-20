// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "BuildSystemPlugins",
    products: [
        .plugin(name: "choco-build-plugin", targets: ["ChocoBuildPlugin"])
    ],
    dependencies: [],
    targets: [
        .plugin(
            name: "ChocoBuildPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "swiftlint"),
                .target(name: "swiftgen"),
                .target(name: "sourcery")
            ]
        ),
        .binaryTarget(
            name: "swiftlint",
            path: "swiftlint.artifactbundle"
        ),
        .binaryTarget(
            name: "swiftgen",
            path: "swiftgen.artifactbundle"
        ),
        .binaryTarget(
            name: "sourcery",
            path: "sourcery.artifactbundle"
        )
    ]
)
