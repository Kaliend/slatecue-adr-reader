import Foundation

enum ShellCommandError: LocalizedError {
    case commandFailed(executable: String, status: Int32, errorOutput: String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(executable, status, errorOutput):
            if errorOutput.isEmpty {
                return AppStrings.currentFormat(
                    "error.command_failed_without_output",
                    arguments: [executable, Int(status)]
                )
            }
            return AppStrings.currentFormat(
                "error.command_failed_with_output",
                arguments: [executable, Int(status), errorOutput]
            )
        }
    }
}

struct ShellCommand {
    @discardableResult
    static func run(
        executable: String,
        arguments: [String],
        currentDirectoryURL: URL? = nil
    ) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorOutput = String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            throw ShellCommandError.commandFailed(
                executable: executable,
                status: process.terminationStatus,
                errorOutput: errorOutput
            )
        }

        return output
    }
}
