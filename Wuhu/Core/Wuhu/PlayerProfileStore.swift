import Foundation

/// Stub player profile until full onboarding ships. Persisted in UserDefaults.
@MainActor
@Observable
final class PlayerProfileStore {
    private static let storageKey = "wuhuPlayerProfile_v1"
    /// Key used before the WooHoo → Wuhu rename; read once and migrated.
    private static let legacyStorageKey = "woohooPlayerProfile_v1"

    private(set) var profile: AthleteOnboardingEngine.PlayerProfile?

    init() {
        Self.migrateLegacyKeyIfNeeded()
        load()
    }

    private static func migrateLegacyKeyIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.data(forKey: storageKey) == nil,
              let legacy = defaults.data(forKey: legacyStorageKey) else { return }
        defaults.set(legacy, forKey: storageKey)
        defaults.removeObject(forKey: legacyStorageKey)
    }

    func load() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.storageKey),
            let decoded = try? JSONDecoder().decode(AthleteOnboardingEngine.PlayerProfile.self, from: data)
        else {
            profile = nil
            return
        }
        profile = decoded
    }

    func save(_ profile: AthleteOnboardingEngine.PlayerProfile) {
        self.profile = profile
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    func clear() {
        profile = nil
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    var weeklyPerformanceMode: WeeklyPerformanceMode {
        switch profile?.selectedSport {
        case .powerlifting: return .powerlifting
        case .running, .none: return .running
        }
    }

    func wslPresentation() -> WSLScorePresentation {
        if let eval = profile?.wslEvaluation {
            return WSLScorePresentation.from(evaluation: eval)
        }
        // Home uses `AppEnvironment.wslPresentation`, which estimates from available data.
        return .collectingProfile
    }
}
