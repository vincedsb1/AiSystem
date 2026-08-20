import Foundation

struct CommandResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
    let duration: TimeInterval

    var succeeded: Bool { exitCode == 0 }
}
