import Foundation

/// Gemini chat credentials from `Secrets.xcconfig` → build settings → Info.plist.
///
/// Keys starting with `AIza` (AI Studio) and `AQ.` (Google auth tokens) both use the
/// Generative Language API base URL below — not Vertex `aiplatform.googleapis.com`.
enum GeminiConfiguration {
    static let defaultBaseURL = "https://generativelanguage.googleapis.com/v1beta"
    static let defaultModel = "gemini-3.8-flash"
    private static let placeholderKey = "your_gemini_api_key_here"

    static var apiKey: String {
        value(for: "GEMINI_API_KEY")
    }

    static var model: String {
        let raw = value(for: "GEMINI_MODEL")
        return raw.isEmpty ? defaultModel : raw
    }

    static var baseURLString: String {
        let raw = value(for: "GEMINI_BASE_URL")
        return raw.isEmpty ? defaultBaseURL : raw
    }

    static var baseURL: URL? {
        URL(string: baseURLString)
    }

    static var isConfigured: Bool {
        !apiKey.isEmpty && apiKey != placeholderKey && !apiKey.hasPrefix("$(")
    }

    /// Lightweight reachability check (no health context). Used from Settings.
    static func probeConnection() async -> Result<Void, ChatLLMError> {
        guard isConfigured, let url = baseURL else {
            return .failure(.invalidRequest)
        }
        let client = GeminiChatClient(apiKey: apiKey, baseURL: url, model: model)
        do {
            _ = try await client.complete(
                systemInstructions: [],
                messages: [ChatLLMMessage(role: .user, content: "Reply with exactly: ok")],
                tools: [],
                temperature: 0
            )
            return .success(())
        } catch let error as ChatLLMError {
            return .failure(error)
        } catch {
            return .failure(ChatLLMError.fromTransport(error))
        }
    }

    private static func value(for key: String) -> String {
        let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
        return raw
            .replacingOccurrences(of: "\\/", with: "/")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
