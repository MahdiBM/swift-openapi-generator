//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import PackagePlugin
import Foundation

@main
struct SwiftOpenAPIGeneratorPlugin {
    func runCommand(
        targetWorkingDirectory: Path,
        tool: (String) throws -> PluginContext.Tool,
        sourceFiles: FileList,
        targetName: String
    ) throws {
        let inputs = try PluginUtils.validateInputs(
            workingDirectory: targetWorkingDirectory,
            tool: tool,
            sourceFiles: sourceFiles,
            targetName: targetName,
            pluginSource: .command
        )

        let toolUrl = URL(fileURLWithPath: inputs.tool.path.string)
        let process = Process()
        process.executableURL = toolUrl
        process.arguments = inputs.arguments
        process.environment = [:]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw PluginError.generatorFailure(targetName: targetName)
        }
    }
}

extension SwiftOpenAPIGeneratorPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let targetNameArguments = arguments.filter({ $0 != "--target" })
        let targets: [Target]
        if targetNameArguments.isEmpty {
            targets = context.package.targets
        } else {
            let matchingTargets = try context.package.targets(named: targetNameArguments)
            let withDependencies = matchingTargets.flatMap { [$0] + $0.recursiveTargetDependencies }
            let packageTargets = Set(context.package.targets.map(\.id))
            let withLocalDependencies = withDependencies.filter { packageTargets.contains($0.id) }
            let enumeratedKeyValues = withLocalDependencies.map(\.id).enumerated().map { (key: $0.element, value: $0.offset) }
            let indexLookupTable = Dictionary(enumeratedKeyValues, uniquingKeysWith: { l, _ in l })
            let groupedByID = Dictionary(grouping: withLocalDependencies, by: \.id)
            let sortedUniqueTargets = groupedByID.map(\.value[0]).sorted {
                indexLookupTable[$0.id, default: 0] < indexLookupTable[$1.id, default: 0]
            }
            targets = sortedUniqueTargets
        }

        guard !targets.isEmpty else {
            throw PluginError.noTargetsMatchingTargetNames(targetNameArguments)
        }

        var hadASuccessfulRun = false

        for target in targets {
            guard let swiftTarget = target as? SwiftSourceModuleTarget else {
                print("- Target '\(target.name)': Not a Swift source module. Can't generate OpenAPI code.")
                continue
            }
            do {
                try runCommand(
                    targetWorkingDirectory: target.directory,
                    tool: context.tool,
                    sourceFiles: swiftTarget.sourceFiles,
                    targetName: target.name
                )
                print("- Target '\(target.name)': OpenAPI code generation successfully completed.")
                hadASuccessfulRun = true
            } catch let error as PluginError {
                if error.isMisconfigurationError {
                    throw error
                } else {
                    let fileNames = FileError.Kind.allCases.map(\.name)
                        .joined(separator: ", ", lastSeparator: " or ")
                    print("- Target '\(target.name)': OpenAPI code generation failed. No expected \(fileNames) files.")
                }
            }
        }

        guard hadASuccessfulRun else {
            throw PluginError.noTargetsWithExpectedFiles(targetNames: targets.map(\.name))
        }
    }
}
