import Foundation

/// Runtime Gemini chat status for Settings and debugging (never stores the API key).
enum GeminiChatDiagnostics {
    private static let lastErrorKey = "geminiLastChatError"
    private static let lastSuccessKey = "geminiLastSuccessAt"

    static var lastError: String? {
        get { UserDefaults.standard.string(forKey: lastErrorKey) }
        set {
            if let newValue, !newValue.isEmpty {
                UserDefaults.standard.set(newValue, forKey: lastErrorKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastErrorKey)
            }
        }
    }

    static var lastSuccessAt: Date? {
        get { UserDefaults.standard.object(forKey: lastSuccessKey) as? Date }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: lastSuccessKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastSuccessKey)
            }
        }
    }

    static func recordSuccess() {
        lastError = nil
        lastSuccessAt = Date()
    }

    static func recordFailure(_ message: String) {
        lastError = message
    }

    /// Settings row: configured / not configured / consent off / last error (no key material).
    static func statusLabel(aiScoringConsent: Bool) -> String {
        guard GeminiConfiguration.isConfigured else {
            return "Not configured"
        }
        guard aiScoringConsent else {
            return "Configured — turn on AI consent to use Gemini"
        }
        if lastError != nil {
            return "Last error"
        }
        if lastSuccessAt != nil {
            return "Configured"
        }
        return "Configured — not tested this session"
    }

    static func statusDetail(aiScoringConsent: Bool) -> String? {
        if !GeminiConfiguration.isConfigured {
            return "Add GEMINI_API_KEY to Secrets.xcconfig, then rebuild the app."
        }
        if !aiScoringConsent {
            return nil
        }
        if let lastError {
            return lastError
        }
        if let lastSuccessAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Last successful request \(formatter.localizedString(for: lastSuccessAt, relativeTo: .now))."
        }
        return "Send a chat message or tap Test connection below."
    }
}
