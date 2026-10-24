import Foundation

/// Parsing and formatting for Workout Hub inputs (time, pace, distance, weight).
enum HubFormat {
    /// Accepted input ranges; values outside are rejected rather than saved.
    static let weightRange = 0.0...2_000.0
    static let repsRange = 0...200
    static let milesRange = 0.0...200.0
    static let secondsRange = 1.0...(24.0 * 3600)
    static let heartRateRange = 30.0...230.0

    /// Parses "mm:ss", "h:mm:ss", or plain minutes ("8.5") into seconds. Returns `nil` if invalid.
    static func parseDuration(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        let seconds: Double?
        switch parts.count {
        case 1:
            seconds = Double(parts[0]).map { $0 * 60 }
        case 2:
            guard let m = Int(parts[0]), let s = Double(parts[1]), s < 60, m >= 0 else { return nil }
            seconds = Double(m) * 60 + s
        case 3:
            guard let h = Int(parts[0]), let m = Int(parts[1]), let s = Double(parts[2]),
                  m < 60, s < 60, h >= 0 else { return nil }
            seconds = Double(h) * 3600 + Double(m) * 60 + s
        default:
            seconds = nil
        }
        guard let seconds, secondsRange.contains(seconds) else { return nil }
        return seconds
    }

    /// "8:05" or "1:02:30".
    static func duration(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    /// "8:12 /mi".
    static func pace(_ secondsPerMile: Double) -> String {
        "\(duration(secondsPerMile)) /mi"
    }

    static func miles(_ value: Double) -> String {
        String(format: value >= 10 ? "%.1f mi" : "%.2f mi", value)
    }

    static func weight(_ lbs: Double) -> String {
        lbs.rounded() == lbs ? String(format: "%.0f", lbs) : String(format: "%.1f", lbs)
    }

    static func parseNumber(_ text: String, in range: ClosedRange<Double>) -> Double? {
        let cleaned = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), range.contains(value) else { return nil }
        return value
    }

    /// "1h 05m" / "42m".
    static func elapsed(minutes: Double) -> String {
        let total = Int(minutes.rounded())
        return total >= 60 ? String(format: "%dh %02dm", total / 60, total % 60) : "\(total)m"
    }
}
