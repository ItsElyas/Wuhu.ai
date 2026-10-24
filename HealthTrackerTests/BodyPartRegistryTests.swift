import Testing
@testable import HealthTracker

struct BodyPartRegistryTests {
    @Test func entityNamesCoverEveryCase() {
        #expect(BodyPartRegistry.entityNamesMatchEnum())
        for part in BodyPart.allCases {
            #expect(BodyPartRegistry.part(named: part.rawValue) == part)
        }
    }

    @Test func healingRecommendationsExistForInjuredParts() {
        for part in BodyPart.allCases {
            let tip = HealingRecommendations.recommendation(for: part, severity: 3)
            #expect(!tip.tips.isEmpty)
            #expect(tip.part == part)
        }
    }
}
