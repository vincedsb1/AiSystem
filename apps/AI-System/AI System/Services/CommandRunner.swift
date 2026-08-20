import Foundation

enum CommandRunnerError: Error, LocalizedError {
    case scriptNotFound
    case launchFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .scriptNotFound:
            return "Backend script not found at \(AISystemPaths.scriptPath)"
        case .launchFailed(let underlying):
            return "Failed to launch backend script: \(underlying.localizedDescription)"
        }
    }
}

actor CommandRunner {
    private var currentProcess: Process?

    func run(action: String, args: [String] = []) async throws -> CommandResult {
        guard FileManager.default.fileExists(atPath: AISystemPaths.scriptPath) else {
            throw CommandRunnerError.scriptNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["bash", AISystemPaths.scriptPath, action] + args
        process.currentDirectoryURL = URL(fileURLWithPath: AISystemPaths.root)

        var environment = ProcessInfo.processInfo.environment
        environment["AI_SYSTEM_UI_MODE"] = "swift"
        process.environment = environment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdoutBox = DataBox()
        let stderrBox = DataBox()

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty { stdoutBox.append(data) }
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty { stderrBox.append(data) }
        }

        let start = Date()

        let exitCode: Int32 = try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { proc in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(returning: proc.terminationStatus)
            }
            do {
                try process.run()
                self.currentProcess = process
            } catch {
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(throwing: CommandRunnerError.launchFailed(underlying: error))
            }
        }

        currentProcess = nil
        let duration = Date().timeIntervalSince(start)

        return CommandResult(
            stdout: String(data: stdoutBox.data, encoding: .utf8) ?? "",
            stderr: String(data: stderrBox.data, encoding: .utf8) ?? "",
            exitCode: exitCode,
            duration: duration
        )
    }

    func cancelCurrent() {
        currentProcess?.terminate()
    }
}

private final class DataBox: @unchecked Sendable {
    private var storage = Data()
    private let lock = NSLock()

    func append(_ data: Data) {
        lock.lock()
        storage.append(data)
        lock.unlock()
    }

    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}
