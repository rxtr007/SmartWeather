import Foundation

/// Structured errors encountered during Open-Meteo API communication.
public enum OpenMeteoError: Error, LocalizedError, Equatable, Sendable {
    case invalidURL(String)
    case httpError(statusCode: Int)
    case decodingError(String)
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .httpError(let statusCode):
            return "Server returned HTTP \(statusCode)"
        case .decodingError(let message):
            return "Failed to parse weather data: \(message)"
        case .networkError(let message):
            return "Network connection error: \(message)"
        }
    }
}
