import Foundation

// MARK: - Centralized JSON Decoder with Versioning

class BackendJSONDecoder {
    static let shared = BackendJSONDecoder()

    private let decoder: JSONDecoder

    init() {
        decoder = JSONDecoder()
        // Dates should be ISO 8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - List Projects Decoding

    func decodeListProjects(from data: Data) -> Result<ListProjectsResponse, BackendDecodingError> {
        do {
            let response = try decoder.decode(ListProjectsResponse.self, from: data)

            // Validate schema version
            if response.schemaVersion != PROJECT_SKILLS_SCHEMA_VERSION {
                return .failure(.schemaVersionMismatch(
                    expected: PROJECT_SKILLS_SCHEMA_VERSION,
                    got: response.schemaVersion
                ))
            }

            return .success(response)
        } catch {
            return .failure(.decodingFailed(error.localizedDescription))
        }
    }

    // MARK: - Scan Project Decoding

    func decodeScanProject(from data: Data) -> Result<ScanProjectResponse, BackendDecodingError> {
        do {
            let response = try decoder.decode(ScanProjectResponse.self, from: data)

            // Validate schema version
            if response.schemaVersion != PROJECT_SKILLS_SCHEMA_VERSION {
                return .failure(.schemaVersionMismatch(
                    expected: PROJECT_SKILLS_SCHEMA_VERSION,
                    got: response.schemaVersion
                ))
            }

            return .success(response)
        } catch {
            return .failure(.decodingFailed(error.localizedDescription))
        }
    }

    // MARK: - Generic Decoding

    func decode<T: Decodable>(_ type: T.Type, from data: Data) -> Result<T, BackendDecodingError> {
        do {
            let value = try decoder.decode(T.self, from: data)
            return .success(value)
        } catch {
            return .failure(.decodingFailed(error.localizedDescription))
        }
    }

    // MARK: - String Decoding (for backwards compatibility)

    func decodeListProjects(from string: String) -> Result<ListProjectsResponse, BackendDecodingError> {
        guard let data = string.data(using: .utf8) else {
            return .failure(.invalidData("Cannot convert string to UTF-8 data"))
        }
        return decodeListProjects(from: data)
    }

    func decodeScanProject(from string: String) -> Result<ScanProjectResponse, BackendDecodingError> {
        guard let data = string.data(using: .utf8) else {
            return .failure(.invalidData("Cannot convert string to UTF-8 data"))
        }
        return decodeScanProject(from: data)
    }
}

// MARK: - Custom Decoding Error

enum BackendDecodingError: LocalizedError, Equatable {
    case schemaVersionMismatch(expected: Int, got: Int)
    case invalidData(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .schemaVersionMismatch(let expected, let got):
            return "Schema version mismatch: expected \(expected), got \(got)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .decodingFailed(let message):
            return "Decoding failed: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .schemaVersionMismatch:
            return "The backend API version may have changed. Please update the app."
        case .invalidData:
            return "The data received from the backend is malformed."
        case .decodingFailed:
            return "Could not parse the response from the backend."
        }
    }

    static func == (lhs: BackendDecodingError, rhs: BackendDecodingError) -> Bool {
        switch (lhs, rhs) {
        case (.schemaVersionMismatch(let e1, let g1), .schemaVersionMismatch(let e2, let g2)):
            return e1 == e2 && g1 == g2
        case (.invalidData(let m1), .invalidData(let m2)):
            return m1 == m2
        case (.decodingFailed(let m1), .decodingFailed(let m2)):
            return m1 == m2
        default:
            return false
        }
    }
}

// MARK: - Backend Error Extension

extension BackendError: Error {}
