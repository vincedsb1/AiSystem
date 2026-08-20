import Foundation

// MARK: - Injectable backend boundary

/// Minimal seam so view models can be driven by fixtures in tests.
protocol BackendExecuting: Sendable {
    func run(action: String, args: [String]) async -> CommandResult
}

extension BackendExecuting {
    func run(action: String) async -> CommandResult {
        await run(action: action, args: [])
    }
}

/// Production implementation: delegates to the existing `CommandRunner` actor,
/// which keeps using `Process` with a separate argument array (C-ARCH-04/05).
struct ProcessBackend: BackendExecuting {
    private let runner = CommandRunner()

    func run(action: String, args: [String] = []) async -> CommandResult {
        do {
            return try await runner.run(action: action, args: args)
        } catch {
            return CommandResult(
                stdout: "",
                stderr: error.localizedDescription,
                exitCode: -1,
                duration: 0
            )
        }
    }
}

// MARK: - Service errors

enum ProjectSkillsServiceError: LocalizedError, Equatable {
    /// The backend returned a structured business error.
    case backend(BackendError)
    /// The process failed before producing a decodable payload.
    case processFailed(exitCode: Int32, stderr: String)
    /// The payload could not be decoded (malformed or unknown schema).
    case decoding(BackendDecodingError)

    var errorDescription: String? {
        switch self {
        case .backend(let error):
            return error.message
        case .processFailed(let exitCode, let stderr):
            let detail = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            if detail.isEmpty {
                return "Le backend s'est arrêté avec le code \(exitCode)."
            }
            return detail.components(separatedBy: .newlines).last ?? detail
        case .decoding(let error):
            return error.errorDescription
        }
    }

    /// Stable business code when available, for mapping to French copy.
    var code: String? {
        if case .backend(let error) = self { return error.code }
        return nil
    }

    var isRetryable: Bool {
        switch self {
        case .backend(let error):
            return error.retryable ?? true
        case .processFailed:
            return true
        case .decoding:
            return false
        }
    }
}

// MARK: - Service

/// Read-only access to the project-skills backend routes.
///
/// The service decodes structured JSON only. It never parses human stdout and
/// never derives a business status itself (spec 21.8).
struct ProjectSkillsService {
    private let backend: BackendExecuting
    private let decoder: BackendJSONDecoder

    init(
        backend: BackendExecuting = ProcessBackend(),
        decoder: BackendJSONDecoder = BackendJSONDecoder.shared
    ) {
        self.backend = backend
        self.decoder = decoder
    }

    // MARK: Routes

    func overview() async -> Result<SystemOverviewResponse, ProjectSkillsServiceError> {
        await load(action: "project-overview", args: []) { data in
            decoder.decode(SystemOverviewResponse.self, from: data)
        }
    }

    func listProjects() async -> Result<ListProjectsResponse, ProjectSkillsServiceError> {
        await load(action: "project-list", args: []) { data in
            decoder.decodeListProjects(from: data)
        }
    }

    func scan(project: String) async -> Result<ScanProjectResponse, ProjectSkillsServiceError> {
        // Each user-supplied value stays a separate argv item (C-ARCH-05).
        await load(action: "project-scan", args: [project]) { data in
            decoder.decodeScanProject(from: data)
        }
    }

    // MARK: Mutating routes

    /// Imports an unmanaged skill. Each value stays a separate argv item.
    func importSkill(
        project: String,
        skill: String,
        source: ImportSource
    ) async -> Result<ProjectActionResponse, ProjectSkillsServiceError> {
        await load(
            action: "project-import",
            args: [project, skill, source.rawValue]
        ) { data in
            decoder.decode(ProjectActionResponse.self, from: data)
        }
    }

    /// Synchronises a project's exports. `dryRun` asks the backend for a
    /// preview and guarantees no write (spec 12.3).
    func syncProject(
        project: String,
        dryRun: Bool = false
    ) async -> Result<ProjectActionResponse, ProjectSkillsServiceError> {
        var args = [project]
        if dryRun { args.append("--dry-run") }
        return await load(action: "project-sync", args: args) { data in
            decoder.decode(ProjectActionResponse.self, from: data)
        }
    }

    /// Runs the official global check. Returns the raw result: the caller owns
    /// it, and no other view observes it (spec 20.5).
    func runFullCheck() async -> CommandResult {
        await backend.run(action: "check", args: [])
    }

    /// Opens a resource (report, document) through the backend wrapper.
    @discardableResult
    func openResource(_ action: String) async -> CommandResult {
        await backend.run(action: action, args: [])
    }

    // MARK: Shared decoding pipeline

    private func load<T>(
        action: String,
        args: [String],
        decode: (Data) -> Result<T, BackendDecodingError>
    ) async -> Result<T, ProjectSkillsServiceError> {
        let result = await backend.run(action: action, args: args)

        guard let data = Self.jsonPayload(from: result.stdout) else {
            return .failure(.processFailed(exitCode: result.exitCode, stderr: result.stderr))
        }

        // A non-zero exit with a decodable envelope still carries the business
        // error, which is more useful than the exit code alone (FR-STATE-02).
        if let backendError = Self.structuredError(in: data, using: decoder) {
            return .failure(.backend(backendError))
        }

        switch decode(data) {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            if !result.succeeded {
                return .failure(.processFailed(exitCode: result.exitCode, stderr: result.stderr))
            }
            return .failure(.decoding(error))
        }
    }

    /// Isolates the JSON envelope from any leading banner the shell wrapper
    /// writes before the payload.
    static func jsonPayload(from stdout: String) -> Data? {
        guard let start = stdout.firstIndex(of: "{"),
              let end = stdout.lastIndex(of: "}"),
              start < end
        else { return nil }
        return String(stdout[start...end]).data(using: .utf8)
    }

    private static func structuredError(
        in data: Data,
        using decoder: BackendJSONDecoder
    ) -> BackendError? {
        guard case .success(let envelope) = decoder.decode(ErrorEnvelope.self, from: data),
              envelope.status == "error",
              let error = envelope.error
        else { return nil }
        return error
    }

    private struct ErrorEnvelope: Decodable {
        let status: String
        let error: BackendError?
    }
}
