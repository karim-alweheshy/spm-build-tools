import Foundation
import PackagePlugin

@main
struct Main: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        var commands = [Command]()
        try commands.append(lintCommand(context: context, target: target))
        try commands.append(contentsOf: self.commands(implementationTarget: target, in: context))
        try commands.append(contentsOf: self.commands(mockTarget: target, in: context))
        try commands.append(contentsOf: self.commands(testTarget: target, in: context))
        return commands
    }

    private func lintCommand(context: PluginContext, target: Target) throws -> Command {
        let executablePath = try context.tool(named: "swiftlint").path
        return Command.buildCommand(
            displayName: "Linting \(target.name)",
            executable: executablePath,
            arguments: [
                "lint",
                "--config",
                executablePath.removingLastComponent().string + "/.swiftlint.yml",
                "--strict",
                "--no-cache",
                "--in-process-sourcekit",
                "--path",
                target.directory.string
            ],
            environment: [:]
        )
    }

    private func commands(implementationTarget target: Target, in context: PluginContext) throws -> [Command] {
        let isImplementationModule = target.name == context.package.displayName
        guard isImplementationModule else { return [] }

        let executable = try context.tool(named: "swiftgen").path
        let generatedFilesFolder = context.pluginWorkDirectory
        var swiftGenCommands = [Command]()

        if let storyboard = try filePaths(in: target.directory.string, suffix: ".storyboard") {
            let inputFile = target.directory.appending(storyboard)
            let outputFiles = generatedFilesFolder.appending("Scenes.swift")
            swiftGenCommands.append(
                .buildCommand(
                    displayName: "Swiftgen scenes \(target.name)",
                    executable: executable,
                    arguments: [
                        "run", "ib", "--templateName", "scenes-swift5",
                        "--param", "module=\(target.name)",
                        "--param", "ignoreTargetModule",
                        "--output", "\(generatedFilesFolder)/Scenes.swift",
                        target.directory.string
                    ],
                    environment: [:],
                    inputFiles: [inputFile],
                    outputFiles: [outputFiles]
                )
            )
        }

        if let strings = try filePaths(in: target.directory.string, suffix: "en.lproj/Localizable.strings") {
            let inputFile = target.directory.appending(strings)
            let outputFiles = generatedFilesFolder.appending("Strings.swift")
            swiftGenCommands.append(
                .buildCommand(
                    displayName: "Swiftgen strings \(target.name)",
                    executable: executable,
                    arguments: [
                        "run", "strings", "--templateName", "structured-swift5",
                        "--output", "\(generatedFilesFolder)/Strings.swift",
                        inputFile
                    ],
                    environment: [:],
                    inputFiles: [inputFile],
                    outputFiles: [outputFiles]
                )
            )
        }

        if let assets = try filePaths(in: target.directory.string, suffix: ".xcassets") {
            let inputFile = target.directory.appending(assets)
            let outputFiles = generatedFilesFolder.appending("Assets.swift")
            swiftGenCommands.append(
                .buildCommand(
                    displayName: "Swiftgen assets \(target.name)",
                    executable: executable,
                    arguments: [
                        "run", "xcassets", "--templateName", "swift5",
                        "--param", "forceProvidesNamespaces",
                        "--output", "\(generatedFilesFolder)/Assets.swift",
                        inputFile
                    ],
                    environment: [:],
                    inputFiles: [inputFile],
                    outputFiles: [outputFiles]
                )
            )
        }
        return swiftGenCommands
    }

    private func filePaths(in urlPath: String, suffix: String) throws -> String? {
        FileManager.default
            .enumerator(atPath: urlPath)?
            .allObjects
            .compactMap { $0 as? String }
            .first { $0.hasSuffix(suffix) }
    }

    private func commands(mockTarget: Target, in context: PluginContext) throws -> [Command] {
        guard mockTarget.name.contains("Mocks") else { return [] }
        let toolPath = try context.tool(named: "sourcery")
        let interfaceModule = mockTarget.name.replacingOccurrences(of: "Mocks", with: "Interface")
        let targets = mockTarget.recursiveTargetDependencies.map(\.name)
        let sourceryCommand = Command.prebuildCommand(
            displayName: "Sourcery mocks \(mockTarget.name)",
            executable: toolPath.path,
            arguments: [
                "--templates",
                toolPath.path.removingLastComponent().removingLastComponent().appending("Templates"),
                "--args",
                "imports=[\"UIKit\", \"Combine\", \(targets.map { "\"\($0)\"" }.joined(separator: ","))]",
                "--sources",
                context.package.directory.appending("Sources", interfaceModule),
                "--output",
                context.pluginWorkDirectory,
                "--disableCache",
                "--verbose"
            ],
            environment: [:],
            outputFilesDirectory: context.pluginWorkDirectory
        )
        return [sourceryCommand]
    }

    private func commands(testTarget: Target, in context: PluginContext) throws -> [Command] {
        guard testTarget.name.contains("Tests") else { return [] }
        let toolPath = try context.tool(named: "sourcery")
        let implementationModule = context.package.targets.first { $0.name == context.package.displayName }!
        let targets = implementationModule.recursiveTargetDependencies.map(\.name)
        let sourceryCommand = Command.prebuildCommand(
            displayName: "Sourcery mocks \(testTarget.name)",
            executable: toolPath.path,
            arguments: [
                "--templates",
                toolPath.path.removingLastComponent().removingLastComponent().appending("Templates"),
                "--args",
                "imports=[\"UIKit\", \"Combine\", \(targets.map { "\"\($0)\"" }.joined(separator: ","))],testableImports=[\"\(implementationModule.name)\"]",
                "--sources",
                context.package.directory.appending("Sources", implementationModule.name),
                "--output",
                context.pluginWorkDirectory,
                "--disableCache",
                "--verbose"
            ],
            environment: [:],
            outputFilesDirectory: context.pluginWorkDirectory
        )
        return [sourceryCommand]
    }
}
