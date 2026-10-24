import Foundation

/// System instructions for the chat LLM.
/// `WuhuMasterPrompt.text` is the persona; `toolRules` maps the prompt's "backend functions"
/// to what the app actually provides, so Body Map updates keep working if the persona text changes.
enum ChatSystemPrompt {
    static let toolRules = """
    ## APP INTEGRATION (how "the backend" works in this app)

    - Context: the official numbers you may use are in the "Compact health context JSON" below. That is everything the app has retrieved for this turn. If a value (for example workouts, weight, or profile fields) is missing or null, say it is not available yet instead of estimating it.
    - WSL Score: `wslTier` / `wslScore` (out of 6.0) / `wslConfidencePercent` are the official WSL values. If `wslEstimatedFields` is present, some inputs were estimated by the app; say the score is provisional and suggest adding those details for a firmer score.
    - Wear & Tear state in the context: `wear` lists parts with backend levels slight (yellow), high (orange), severe (red); parts not listed are normal. `bodyStatus` lists user-reported statuses (sore / injured). Use these, never invent colors.
    - Submitting updates: the only write function is `update_wear_and_tear`. Call it when the user reports soreness, pain, an injury, or that a part feels better. Use the exact `part` ids from the schema, one entry per side (left and right are separate parts).
      - status "sore" for soreness or fatigue; "injured" only when the user says the area is injured or in pain; "healthy" only when the user says it has recovered (never because time passed).
      - severity 1 (mild) to 5 (severe), based on how the user describes it.
      - Training a muscle group alone (no soreness or pain) does not need a call; logged workouts update Wear & Tear automatically.
    - Confirmation: updates are applied and validated after your reply, and the app tells the user what was saved or skipped. Say you are logging it ("I'm logging that on your Wear & Tear"), not that it is already updated.
    - Always include a short text reply to the user in the same response as any function call.
    - Never encourage training through a part marked injured; suggest safe alternatives and point the user to the Body Map heal tips. You give general wellness and fitness guidance, not medical diagnoses.
    """

    /// Ordered system instructions: persona, integration rules, optional Wuhu dossier, then health context.
    static func instructions(
        contextJSON: String,
        playerProfile: AthleteOnboardingEngine.PlayerProfile? = nil,
        wslEvaluation: WSLCompositeEvaluation? = nil
    ) -> [String] {
        var blocks = [WuhuMasterPrompt.text, toolRules]
        if let playerProfile {
            blocks.append(WuhuChatContext.systemPromptSection(for: playerProfile, evaluation: wslEvaluation))
        }
        blocks.append("Compact health context JSON (today, this week, scores, body status): \(contextJSON)")
        return blocks
    }
}
