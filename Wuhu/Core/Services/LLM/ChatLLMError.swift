import Foundation

/// Failures from a chat LLM client. Messages never include health data or keys.
enum ChatLLMError: LocalizedError, Equatable {
    case invalidRequest
    case http(status: Int, message: String?)
    case blocked(reason: String)
    case invalidResponse
    case transport(code: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "The chat request could not be built. Check GEMINI_MODEL and GEMINI_BASE_URL in Secrets.xcconfig."
        case let .http(status, message):
            if status == 401 || status == 403 {
                return "Gemini rejected the API key (\(status)). Confirm GEMINI_API_KEY in Secrets.xcconfig and rebuild."
            }
            if status == 400 {
                return "Gemini rejected the request (400)\(message.map { ": \($0)" } ?? ".")"
            }
            if status == 429 {
                return "Gemini rate limit reached. Try again in a moment."
            }
            if status == 503 || status == 500 {
                return "Gemini is busy right now (\(status)). Try again in a moment."
            }
            if status == 404 {
                return "Gemini could not find that model (404). Set GEMINI_MODEL to gemini-3.8-flash (or another model your key supports)."
            }
            return "Gemini returned an error (\(status))\(message.map { ": \($0)" } ?? ".")"
        case let .blocked(reason):
            return "Gemini declined to answer (\(reason))."
        case .invalidResponse:
            return "The Gemini response could not be read."
        case let .transport(code, message):
            return message.isEmpty
                ? "Could not reach Gemini (network error \(code))."
                : message
        }
    }

    /// Maps URLSession and other transport failures to user-facing copy.
    static func fromTransport(_ error: Error) -> ChatLLMError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .transport(code: urlError.errorCode, message: "No internet connection. Check Wi‑Fi or cellular and try again.")
            case .cannotFindHost, .dnsLookupFailed:
                return .transport(code: urlError.errorCode, message: "Could not resolve Gemini’s server. Check GEMINI_BASE_URL in Secrets.xcconfig.")
            case .cannotConnectToHost, .timedOut:
                return .transport(code: urlError.errorCode, message: "Could not connect to Gemini (timeout). Try again on a stable network.")
            case .secureConnectionFailed, .serverCertificateUntrusted:
                return .transport(code: urlError.errorCode, message: "Secure connection to Gemini failed. Check date/time and network settings.")
            default:
                return .transport(code: urlError.errorCode, message: "Network error while contacting Gemini (\(urlError.code.rawValue)).")
            }
        }
        return .transport(code: (error as NSError).code, message: error.localizedDescription)
    }
}
