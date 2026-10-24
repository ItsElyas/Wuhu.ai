import Foundation

/// Gemini system-prompt dossier (ported from R2 Kiro prompt builder — no HTTP client).
enum WuhuChatContext {
    static func systemPromptSection(
        for profile: AthleteOnboardingEngine.PlayerProfile,
        evaluation: WSLCompositeEvaluation? = nil
    ) -> String {
        let citations = DatasetReferenceEngine.formattedCitationsForLLM(
            for: profile.selectedSport,
            gender: profile.gender
        )
        let eval = evaluation ?? profile.wslEvaluation
        let wslLine: String = eval.map {
            "\($0.rank.title) (\(String(format: "%.2f", $0.compositeScore))/6.0, \($0.confidencePercentage)% confidence\($0.isProvisional ? ", estimated" : ""))"
        } ?? "not available yet"

        return """
        Wuhu athlete dossier (grounded S&C context — wellness only, not medical advice):
        - Name: \(profile.name)
        - Biological sex: \(profile.gender.rawValue)
        - Age: \(profile.age), bodyweight: \(profile.weightLbs) lbs, BMI: \(String(format: "%.1f", profile.bmi))
        - Discipline: \(profile.selectedSport.rawValue)
        - WSL Scale: \(wslLine)
        - Goals: \(profile.goals.map(\.rawValue).joined(separator: "; "))

        \(citations)

        Coaching rules: cite the datasets above when explaining load or tier; never prescribe training through injured body parts; progressive overload only when RPE allows.
        """
    }
}
