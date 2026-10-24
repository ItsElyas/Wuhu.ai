import Foundation

/// Rule-based wear parsing for local / no-LLM chat fallback.
enum ChatWearTearActionParser {
    static func userReportsInjury(in lowercasedMessage: String) -> Bool {
        let keywords = ["injur", "hurt", "pain", "ache", "twisted", "sprain", "torn", "pulled", "broken", "swollen"]
        return keywords.contains { lowercasedMessage.contains($0) }
    }

    static func actions(from userMessage: String) -> [ChatWearTearAction] {
        let lower = userMessage.lowercased()
        guard let part = resolvePart(in: lower) else { return [] }

        if lower.contains("clear") || lower.contains("healed") || lower.contains("feels fine")
            || lower.contains("feels good") || lower.contains("no longer sore") {
            return [ChatWearTearAction(part: part.rawValue, status: .healthy, severity: nil, note: nil)]
        }

        if userReportsInjury(in: lower) {
            let severity = parseSeverity(lower) ?? 2
            return [ChatWearTearAction(part: part.rawValue, status: .injured, severity: severity, note: nil)]
        }

        if lower.contains("sore") || lower.contains("tight") || lower.contains("fatigue") {
            let severity = parseSeverity(lower) ?? 2
            return [ChatWearTearAction(part: part.rawValue, status: .sore, severity: severity, note: nil)]
        }

        if lower.contains("hurt") || lower.contains("pain") || lower.contains("ache") {
            let severity = parseSeverity(lower) ?? 2
            return [ChatWearTearAction(part: part.rawValue, status: .injured, severity: severity, note: nil)]
        }

        return []
    }

    static func displayName(for action: ChatWearTearAction) -> String? {
        guard let part = BodyPartRegistry.resolvePart(action.part) else { return nil }
        return "\(part.displayName) (\(action.status.rawValue))"
    }

    private static func parseSeverity(_ lower: String) -> Int? {
        if let match = lower.range(of: #"severity\s*(\d)"#, options: .regularExpression) {
            let token = String(lower[match])
            if let digit = token.last, let value = Int(String(digit)) {
                return min(5, max(1, value))
            }
        }
        return nil
    }

    private static func resolvePart(in lower: String) -> BodyPart? {
        let side: BodyPartSide? = {
            if lower.contains("left ") || lower.hasPrefix("left") || lower.contains(" my left") { return .left }
            if lower.contains("right ") || lower.hasPrefix("right") || lower.contains(" my right") { return .right }
            return nil
        }()

        let candidates: [(keywords: [String], part: (BodyPartSide?) -> BodyPart?)] = [
            (["knee"], { $0 == .left ? .leftKnee : ($0 == .right ? .rightKnee : nil) }),
            (["shoulder"], { $0 == .left ? .leftShoulder : ($0 == .right ? .rightShoulder : nil) }),
            (["hamstring"], { $0 == .left ? .leftHamstring : ($0 == .right ? .rightHamstring : nil) }),
            (["quad"], { $0 == .left ? .leftQuad : ($0 == .right ? .rightQuad : nil) }),
            (["calf"], { $0 == .left ? .leftCalf : ($0 == .right ? .rightCalf : nil) }),
            (["ankle"], { $0 == .left ? .leftAnkle : ($0 == .right ? .rightAnkle : nil) }),
            (["bicep"], { $0 == .left ? .leftBicep : ($0 == .right ? .rightBicep : nil) }),
            (["lower back"], { _ in .lowerBack }),
            (["upper back"], { _ in .upperBack }),
            (["chest"], { _ in .chest }),
            (["neck"], { _ in .neck }),
        ]

        for candidate in candidates {
            guard candidate.keywords.contains(where: { lower.contains($0) }) else { continue }
            if let side, let part = candidate.part(side) { return part }
            if side == nil, candidate.keywords.contains(where: { ["lower back", "upper back", "chest", "neck"].contains($0) }) {
                return candidate.part(.left)
            }
        }
        return nil
    }

    private enum BodyPartSide {
        case left
        case right
    }
}
