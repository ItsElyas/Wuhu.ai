import Foundation
import SwiftUI

/// User preferences persisted in UserDefaults / AppStorage.
@Observable
final class AppSettings {
    static let aiConsentKey = "aiScoringConsent"
    static let aiConsentShownKey = "aiConsentShown"
    static let chronologicalAgeKey = "chronologicalAge"
    static let biologicalSexKey = "biologicalSex"
    static let heightCmKey = "heightCm"
    static let weightKgKey = "weightKg"
    static let stepGoalKey = "stepGoal"
    static let chatWellnessCheckInKey = "chatWellnessCheckInEnabled"
    static let demoModeKey = "demoModeEnabled"

    var aiScoringConsent: Bool {
        didSet { UserDefaults.standard.set(aiScoringConsent, forKey: Self.aiConsentKey) }
    }

    var aiConsentShown: Bool {
        didSet { UserDefaults.standard.set(aiConsentShown, forKey: Self.aiConsentShownKey) }
    }

    var chronologicalAge: Int {
        didSet { UserDefaults.standard.set(chronologicalAge, forKey: Self.chronologicalAgeKey) }
    }

    var biologicalSex: String {
        didSet { UserDefaults.standard.set(biologicalSex, forKey: Self.biologicalSexKey) }
    }

    var heightCm: Double {
        didSet { UserDefaults.standard.set(heightCm, forKey: Self.heightCmKey) }
    }

    var weightKg: Double {
        didSet { UserDefaults.standard.set(weightKg, forKey: Self.weightKgKey) }
    }

    var stepGoal: Int {
        didSet { UserDefaults.standard.set(stepGoal, forKey: Self.stepGoalKey) }
    }

    /// Proactive "how are you feeling?" opener when chat history is empty.
    var chatWellnessCheckInEnabled: Bool {
        didSet { UserDefaults.standard.set(chatWellnessCheckInEnabled, forKey: Self.chatWellnessCheckInKey) }
    }

    /// Demo mode: sample Health data and a separate, pre-seeded local store. Real data is untouched.
    var demoMode: Bool {
        didSet { UserDefaults.standard.set(demoMode, forKey: Self.demoModeKey) }
    }

    /// Last JSON payload sent (debug builds / View data sent screen).
    var lastSnapshotJSON: String = ""
    var lastScoreJSON: String = ""

    init() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "useMockData")
        self.demoMode = defaults.bool(forKey: Self.demoModeKey)
        self.aiScoringConsent = defaults.bool(forKey: Self.aiConsentKey)
        self.aiConsentShown = defaults.bool(forKey: Self.aiConsentShownKey)
        let storedAge = defaults.integer(forKey: Self.chronologicalAgeKey)
        self.chronologicalAge = storedAge > 0 ? storedAge : 22
        self.biologicalSex = defaults.string(forKey: Self.biologicalSexKey) ?? "male"
        let h = defaults.double(forKey: Self.heightCmKey)
        self.heightCm = h > 0 ? h : 178
        let w = defaults.double(forKey: Self.weightKgKey)
        self.weightKg = w > 0 ? w : 76
        let goal = defaults.integer(forKey: Self.stepGoalKey)
        self.stepGoal = goal > 0 ? goal : 10_000
        if defaults.object(forKey: Self.chatWellnessCheckInKey) == nil {
            self.chatWellnessCheckInEnabled = true
        } else {
            self.chatWellnessCheckInEnabled = defaults.bool(forKey: Self.chatWellnessCheckInKey)
        }
    }

    var profileOverride: UserProfile {
        UserProfile(
            ageYears: chronologicalAge,
            biologicalSex: biologicalSex,
            heightCm: heightCm,
            weightKg: weightKg,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -chronologicalAge, to: .now)
        )
    }
}
