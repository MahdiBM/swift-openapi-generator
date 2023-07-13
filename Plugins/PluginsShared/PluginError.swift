import PackagePlugin
import Foundation

enum PluginError: Swift.Error, CustomStringConvertible, LocalizedError {
    case incompatibleTarget(targetName: String)
    case badArguments(arguments: [String])
    // The description is only suitable for Xcode, as it's only thrown in Xcode plugins.
    case noTargetsMatchingTargetName(targetName: String)
    // The description is not suitable for Xcode, as it's not thrown in Xcode plugins.
    case tooManyTargetsMatchingTargetName(targetNames: [String])
    case noConfigFound(targetName: String)
    case noDocumentFound(targetName: String)
    case multiConfigFound(targetName: String, files: [Path])
    case multiDocumentFound(targetName: String, files: [Path])

    var description: String {
        switch self {
        case .incompatibleTarget(let targetName):
            return
            "Incompatible target called '\(targetName)'. Only Swift source targets can be used with the Swift OpenAPI generator plugin."
        case .badArguments(let arguments):
            return "Bad arguments provided: \(arguments). On Xcode, use Xcode's run plugin UI to choose a specific target. On CLI, pass a specific target's name to the command like so: '--target TARGET_NAME'"
        case .noTargetsMatchingTargetName(let targetName):
            return "No target called '\(targetName)' were found. Use Xcode's UI to choose a single specific target before triggering the command plugin."
        case .tooManyTargetsMatchingTargetName(let targetNames):
            return "Too many targets found matching the provided target name: '\(targetNames)'. Target name must be specific enough for the plugin to only find a single target."
        case .noConfigFound(let targetName):
            return
            "No config file found in the target named '\(targetName)'. Add a file called 'openapi-generator-config.yaml' or 'openapi-generator-config.yml' to the target's source directory. See documentation for details."
        case .noDocumentFound(let targetName):
            return
            "No OpenAPI document found in the target named '\(targetName)'. Add a file called 'openapi.yaml', 'openapi.yml' or 'openapi.json' (can also be a symlink) to the target's source directory. See documentation for details."
        case .multiConfigFound(let targetName, let files):
            return
            "Multiple config files found in the target named '\(targetName)', but exactly one is required. Found \(files.map(\.description).joined(separator: " "))."
        case .multiDocumentFound(let targetName, let files):
            return
            "Multiple OpenAPI documents found in the target named '\(targetName)', but exactly one is required. Found \(files.map(\.description).joined(separator: " "))."
        }
    }

    var errorDescription: String? {
        description
    }
}