import Foundation

enum AISystemPaths {
    static let root = "/Users/vincentdesbrosses/Documents/Misc/ai-system"
    static let scriptPath = "\(root)/scripts/ai_system_action.sh"
    static let logsDir = "\(root)/logs"
    static let lastLog = "\(logsDir)/ai-system-last-action.log"
    static let lastLogOut = "\(logsDir)/ai-system-last-action-out.log"
    static let lastLogErr = "\(logsDir)/ai-system-last-action-err.log"
}
