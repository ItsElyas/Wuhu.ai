import Foundation
import Testing
@testable import Wuhu

struct HomeScreenTests {
    @Test func sleepFormatting() {
        #expect(HomeFormat.sleep(minutes: 462) == "7h 42m")
        #expect(HomeFormat.sleep(minutes: 42) == "42m")
        #expect(HomeFormat.sleep(minutes: 60) == "1h")
        #expect(HomeFormat.sleep(minutes: -5) == "0m")
        #expect(!HomeFormat.sleep(minutes: 462).contains("."))
    }

    @Test func groupedNumbersUseLocaleSeparators() {
        #expect(HomeFormat.grouped(8214, locale: Locale(identifier: "en_US")) == "8,214")
        #expect(HomeFormat.grouped(2600, locale: Locale(identifier: "en_US")) == "2,600")
    }

    @Test func injuredManualIsSevereAndAutoNeverIs() {
        #expect(WearMapping.level(status: .injured, severity: 1, intensity: 1, source: .manual) == .severe)
        #expect(WearMapping.level(status: .injured, severity: 5, intensity: 1, source: .autoWorkout) != .severe)
        #expect(WearMapping.level(status: .worked, severity: 5, intensity: 1, source: .autoWorkout) != .severe)
    }

    @Test func highestWearLevelWins() {
        #expect(WearMapping.highest([.slight, .none, .high]) == .high)
        #expect(WearMapping.highest([.severe, .slight]) == .severe)
    }

    @Test func wearMappingIsMonotonic() {
        for severity in 1...5 {
            for higher in severity...5 {
                let lower = WearMapping.level(status: .sore, severity: severity, intensity: 0.2, source: .manual)
                let upper = WearMapping.level(status: .sore, severity: higher, intensity: 0.2, source: .manual)
                #expect(upper >= lower)
            }
        }
        let steps = stride(from: 0.0, through: 1.0, by: 0.1)
        for intensity in steps {
            for higher in steps where higher + 0.0001 >= intensity {
                let lower = WearMapping.level(status: .worked, severity: 1, intensity: intensity, source: .autoWorkout)
                let upper = WearMapping.level(status: .worked, severity: 1, intensity: higher, source: .autoWorkout)
                #expect(upper >= lower)
            }
        }
    }

    @Test func greetingCoversSplitsRestAndMissingName() {
        let named = GreetingCopy.make(firstName: "Elyas", plan: TodayPlan(split: .push, focus: "Upper body"))
        #expect(named.nameLine == "Hello Elyas,")
        #expect(named.accent == "Push Day")
        #expect(named.spoken.contains("we're training Push Day today"))

        for split in Split.allCases where split != .rest {
            let copy = GreetingCopy.make(firstName: "A", plan: TodayPlan(split: split, focus: "x"))
            #expect(copy.accent == split.dayTitle)
            #expect(copy.continuation == "we're training ")
        }

        let rest = GreetingCopy.make(firstName: "A", plan: TodayPlan(split: .rest, focus: "Rest"))
        #expect(rest.accent == "Rest Day")
        #expect(rest.spoken.contains("we're taking a Rest Day today"))

        let none = GreetingCopy.make(firstName: nil, plan: nil)
        #expect(none.nameLine == "Hello there,")
        #expect(none.accent == nil)
        #expect(none.continuation == "ready to train today?")

        #expect(GreetingCopy.firstName(from: "Elyas Khoubach") == "Elyas")
        #expect(GreetingCopy.firstName(from: "  ") == "there")
    }

    @Test func wslTierPlaceholderIsBron() {
        #expect(WSLRank.allCases.map(\.rawValue) == ["Bron", "BronLite", "HTP", "MTP", "LTP", "Sub-Player"])
        #expect(WSLRank.placeholder == .bron)
        #expect(HomeFixture.reference.wslTier == .bron)
        #expect(HomeFixture.empty.wslTier == .bron)
        #expect(HomeState.loading.wslTier == .bron)
    }

    @Test func scoreValidationClampsEgoAndDropsInvalidPlan() {
        var result = ScoreResult(
            schemaVersion: 1,
            vitalityAge: nil,
            readiness: nil,
            effort: nil,
            sleepScore: nil,
            method: nil,
            insufficientData: false,
            disclaimer: nil,
            egoScore: EgoScoreValue(score: 140, summary: "high"),
            dailyRecommendation: DailyRecommendationValue(
                split: "push",
                focus: "Upper body",
                sleepHours: 20,
                workoutMinutes: 55,
                calories: 2600
            )
        )
        result.clamp()
        #expect(result.egoScore?.score == 100)
        #expect(result.validatedDailyPlan() == nil)

        var low = ScoreResult(
            schemaVersion: 1,
            vitalityAge: nil,
            readiness: nil,
            effort: nil,
            sleepScore: nil,
            method: nil,
            insufficientData: false,
            disclaimer: nil,
            egoScore: EgoScoreValue(score: -4, summary: nil),
            dailyRecommendation: DailyRecommendationValue(
                split: "not-a-split",
                focus: "Upper body",
                sleepHours: 8,
                workoutMinutes: 55,
                calories: 2600
            )
        )
        low.clamp()
        #expect(low.egoScore?.score == 0)
        #expect(low.dailyRecommendation == nil)

        let valid = DailyRecommendationValue(
            split: "pull",
            focus: "Pull",
            sleepHours: 8,
            workoutMinutes: 50,
            calories: 2400
        )
        #expect(valid.validated()?.0 == .pull)
        #expect(valid.validated()?.1.calories == 2400)
    }

    @Test func rightQuadIsOnTheViewersLeft() {
        #expect(MiniBodyLayout.viewerSide(of: .rightQuad) == .viewerLeft)
        #expect(MiniBodyLayout.viewerSide(of: .leftQuad) == .viewerRight)
        #expect(MiniBodyLayout.viewerSide(of: .chest) == .center)
    }

    @Test func fallbackAvoidsPushWhenChestIsBlocked() {
        let blocked: Set<BodyPart> = [.chest]
        let plan = HomeRecommendationFallback.plan(on: Date(timeIntervalSince1970: 0), blocked: blocked)
        #expect(plan.0.split != .push)
        #expect(plan.0.split.loadedParts.isDisjoint(with: blocked))
    }
}
