import Foundation
import Observation

enum RunState: Equatable {
    case idle
    case running(action: String)
}

@Observable
final class CommandCenter {
    private let runner = CommandRunner()

    var currentRun: RunState = .idle
    var lastResult: CommandResult?

    var isRunning: Bool {
        currentRun != .idle
    }

    func execute(_ action: BackendAction, args: [String] = []) async {
        guard !isRunning else { return }
        currentRun = .running(action: action.displayName)

        do {
            lastResult = try await runner.run(action: action.cliArgument, args: args)
        } catch {
            lastResult = CommandResult(stdout: "", stderr: error.localizedDescription, exitCode: -1, duration: 0)
        }

        currentRun = .idle
    }

    func executeRaw(action: String, displayName: String, args: [String]) async {
        guard !isRunning else { return }
        currentRun = .running(action: displayName)

        do {
            lastResult = try await runner.run(action: action, args: args)
        } catch {
            lastResult = CommandResult(stdout: "", stderr: error.localizedDescription, exitCode: -1, duration: 0)
        }

        currentRun = .idle
    }
}
