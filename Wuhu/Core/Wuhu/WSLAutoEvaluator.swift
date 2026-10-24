import Foundation

/// Builds a WSL composite from whatever data exists, estimating (interpolating) missing fields
/// so the Home card never stalls on "Collecting profile".
///
/// Resolution order per field: player profile → Apple Health → app settings → population estimate.
/// Every estimated field is listed in `WSLAutoResult.estimatedFields` and lowers confidence.
/// The final number still comes from `AthleteOnboardingEngine.evaluateCompositeWSL`.
enum WSLAutoEvaluator {

    /// One logged strength set (Workout Hub).
    struct LiftSet: Sendable, Equatable {
        var exerciseName: String
        var weightLbs: Double
        var reps: Int
    }

    struct Input: Sendable {
        var profile: AthleteOnboardingEngine.PlayerProfile?
        var healthProfile: UserProfile
        var settingsAge: Int
        var settingsSex: String
        var settingsHeightCm: Double
        var settingsWeightKg: Double
        var dailyHistory: [DailyStats]
        var workouts: [ImportedWorkout]
        var liftSets: [LiftSet]
    }

    struct Result: Sendable, Equatable {
        var evaluation: WSLCompositeEvaluation
        /// Human-readable names of inputs that were estimated, e.g. "5K time".
        var estimatedFields: [String]
    }

    // MARK: - Tunables (documented estimates, not measurements)

    enum Config {
        static let fiveKMiles = 3.10686
        /// Riegel endurance exponent for race-time prediction.
        static let riegelExponent = 1.06
        static let minRunMiles = 0.6
        static let fiveKRangeMinutes = 12.0...60.0
        /// Recreational 5K medians by sex (minutes) before activity/age adjustment.
        static let baseFiveKMale = 30.0
        static let baseFiveKFemale = 35.0
        static let fiveKAgePenaltyPerYearOver30 = 0.15
        static let fiveKPerRHRBeatAbove60 = 0.1
        static let rhrWindowDays = 14
        static let epleyMaxReps = 12
        /// Reference S/B/D share of total (matches the engine's structural ratio).
        static let maleRatio = (squat: 0.35, bench: 0.24, deadlift: 0.41)
        static let femaleRatio = (squat: 0.36, bench: 0.20, deadlift: 0.44)
    }

    // MARK: - Entry point

    static func evaluate(_ input: Input) -> Result {
        var estimated: [String] = []
        var measuredWeight = 0.0
        var totalWeight = 0.0

        /// Tracks how much of the score rests on real data (weights sum to 1).
        func track(_ name: String, measured: Bool, weight: Double) {
            totalWeight += weight
            if measured { measuredWeight += weight } else { estimated.append(name) }
        }

        let age = resolveAge(input)
        track("age", measured: age.measured, weight: 0.05)

        let sex = resolveSex(input)
        track("sex", measured: sex != nil, weight: 0.05)

        let weightLbs = resolveWeightLbs(input)
        let heightInches = resolveHeightInches(input)
        track("body size", measured: weightLbs.measured && heightInches.measured, weight: 0.05)

        let sport = resolveSport(input)
        track("sport", measured: sport.measured, weight: 0.05)

        let activity = resolveActivityLevel(input)
        track("activity level", measured: activity.measured, weight: 0.05)

        let evaluations: [WSLCompositeEvaluation]
        let genders: [AthleteOnboardingEngine.Gender] = sex.map { [$0] } ?? [.male, .female]

        switch sport.value {
        case .running:
            let fiveK = resolveFiveKMinutes(input, sex: sex, age: age.value, activity: activity.value)
            track("5K time", measured: fiveK.measured, weight: 0.5)
            let rhr = resolveRestingHR(input, activity: activity.value)
            track("resting heart rate", measured: rhr.measured, weight: 0.25)
            evaluations = genders.map { gender in
                AthleteOnboardingEngine.evaluateCompositeWSL(
                    sport: .running, gender: gender, age: age.value,
                    bodyweightLbs: weightLbs.value, heightInches: heightInches.value,
                    primaryVal: fiveK.value, subMetricA: rhr.value, subMetricB: nil
                )
            }

        case .powerlifting:
            evaluations = genders.map { gender in
                let lifts = resolveLifts(input, gender: gender, bodyweightLbs: weightLbs.value, activity: activity.value)
                return AthleteOnboardingEngine.evaluateCompositeWSL(
                    sport: .powerlifting, gender: gender, age: age.value,
                    bodyweightLbs: weightLbs.value, heightInches: heightInches.value,
                    primaryVal: lifts.total, subMetricA: lifts.squat, subMetricB: lifts.bench
                )
            }
            let lifts = resolveLifts(input, gender: genders[0], bodyweightLbs: weightLbs.value, activity: activity.value)
            track("lift total", measured: lifts.measuredCount == 3, weight: 0.5)
            track("individual lifts", measured: lifts.measuredCount > 0, weight: 0.25)
        }

        let merged = average(evaluations)
        let confidence = Int((measuredWeight / max(totalWeight, 0.0001) * 100).rounded())
        let clampedConfidence = min(100, max(15, confidence))

        var comment = merged.feedbackComment
        if sex == nil {
            comment += " Sex isn't set, so this averages the male and female scales."
        }
        if !estimated.isEmpty {
            comment += " Estimated from available data: \(estimated.joined(separator: ", ")). Add these for a firmer score."
        }

        let evaluation = WSLCompositeEvaluation(
            sport: merged.sport,
            gender: merged.gender,
            compositeScore: merged.compositeScore,
            rank: merged.rank,
            confidencePercentage: clampedConfidence,
            isProvisional: clampedConfidence < 70,
            subMetrics: merged.subMetrics,
            feedbackComment: comment
        )
        return Result(evaluation: evaluation, estimatedFields: estimated)
    }

    // MARK: - Field resolution

    private struct Resolved<T> {
        var value: T
        var measured: Bool
    }

    private static func resolveAge(_ input: Input) -> Resolved<Int> {
        if let age = input.profile?.age { return Resolved(value: age, measured: true) }
        if let age = input.healthProfile.ageYears, (10...100).contains(age) { return Resolved(value: age, measured: true) }
        // Settings always holds a value (default 22); treat it as user-provided.
        return Resolved(value: min(100, max(10, input.settingsAge)), measured: true)
    }

    /// `nil` means unknown → caller averages both scales.
    private static func resolveSex(_ input: Input) -> AthleteOnboardingEngine.Gender? {
        if let gender = input.profile?.gender { return gender }
        return gender(from: input.healthProfile.biologicalSex) ?? gender(from: input.settingsSex)
    }

    private static func gender(from raw: String?) -> AthleteOnboardingEngine.Gender? {
        switch raw?.lowercased() {
        case "male", "m": return .male
        case "female", "f": return .female
        default: return nil
        }
    }

    private static func resolveWeightLbs(_ input: Input) -> Resolved<Double> {
        if let lbs = input.profile?.weightLbs, lbs > 50 { return Resolved(value: lbs, measured: true) }
        if let kg = input.healthProfile.weightKg, kg > 25 { return Resolved(value: kg * 2.20462, measured: true) }
        return Resolved(value: max(60, input.settingsWeightKg * 2.20462), measured: input.settingsWeightKg > 0)
    }

    private static func resolveHeightInches(_ input: Input) -> Resolved<Double> {
        if let inches = input.profile?.heightInches, inches > 36 { return Resolved(value: inches, measured: true) }
        if let cm = input.healthProfile.heightCm, cm > 100 { return Resolved(value: cm / 2.54, measured: true) }
        return Resolved(value: max(48, input.settingsHeightCm / 2.54), measured: input.settingsHeightCm > 0)
    }

    private static func resolveSport(_ input: Input) -> Resolved<AthleteOnboardingEngine.SportDiscipline> {
        if let sport = input.profile?.selectedSport { return Resolved(value: sport, measured: true) }
        let runs = input.workouts.filter { $0.type == "running" }.count
        let strengthWorkouts = input.workouts.filter { isStrength($0.type) }.count
        let liftSessions = Set(input.liftSets.map(\.exerciseName)).isEmpty ? 0 : 1
        if strengthWorkouts + liftSessions > runs {
            return Resolved(value: .powerlifting, measured: false)
        }
        return Resolved(value: .running, measured: false)
    }

    private static func isStrength(_ type: String) -> Bool {
        let lower = type.lowercased()
        return lower.contains("strength") || lower.contains("weight") || lower.contains("powerlift")
    }

    private static func resolveActivityLevel(_ input: Input) -> Resolved<AthleteOnboardingEngine.ActivityLevel> {
        if let level = input.profile?.activityLevel { return Resolved(value: level, measured: true) }

        let steps = input.dailyHistory.compactMap(\.steps)
        let weeks = max(1.0, Double(min(input.dailyHistory.count, 30)) / 7.0)
        let workoutsPerWeek = Double(input.workouts.count) / weeks
        guard !steps.isEmpty || !input.workouts.isEmpty else {
            return Resolved(value: .moderatelyActive, measured: false)
        }
        let avgSteps = steps.isEmpty ? 0 : Double(steps.reduce(0, +)) / Double(steps.count)

        // Inferred from Health data — real signal, but not the user's own answer.
        let level: AthleteOnboardingEngine.ActivityLevel
        if workoutsPerWeek >= 9 || avgSteps >= 15_000 { level = .competitivePlayer }
        else if workoutsPerWeek >= 5.5 || avgSteps >= 12_000 { level = .veryActive }
        else if workoutsPerWeek >= 3 || avgSteps >= 8_500 { level = .moderatelyActive }
        else if workoutsPerWeek >= 1 || avgSteps >= 5_000 { level = .lightlyActive }
        else { level = .sedentary }
        return Resolved(value: level, measured: true)
    }

    // MARK: - Running

    private static func resolveFiveKMinutes(
        _ input: Input,
        sex: AthleteOnboardingEngine.Gender?,
        age: Int,
        activity: AthleteOnboardingEngine.ActivityLevel
    ) -> Resolved<Double> {
        // Best predicted 5K from real runs (Riegel: T2 = T1 × (D2/D1)^1.06).
        let predictions = input.workouts.compactMap { workout -> Double? in
            guard workout.type == "running",
                  let miles = workout.distanceMiles, miles >= Config.minRunMiles,
                  workout.durationMinutes > 0 else { return nil }
            let predicted = workout.durationMinutes * pow(Config.fiveKMiles / miles, Config.riegelExponent)
            return Config.fiveKRangeMinutes.contains(predicted) ? predicted : nil
        }
        if let best = predictions.min() {
            return Resolved(value: best, measured: true)
        }

        // Interpolate from sex, activity, age, and resting HR.
        let base: Double
        switch sex {
        case .male: base = Config.baseFiveKMale
        case .female: base = Config.baseFiveKFemale
        case nil: base = (Config.baseFiveKMale + Config.baseFiveKFemale) / 2
        }
        let activityOffset: Double
        switch activity {
        case .sedentary: activityOffset = 6
        case .lightlyActive: activityOffset = 3
        case .moderatelyActive: activityOffset = 0
        case .veryActive: activityOffset = -3
        case .competitivePlayer: activityOffset = -6
        }
        let ageOffset = Double(max(0, age - 30)) * Config.fiveKAgePenaltyPerYearOver30
        let rhrOffset = averageRestingHR(input).map { ($0 - 60) * Config.fiveKPerRHRBeatAbove60 } ?? 0
        let estimate = base + activityOffset + ageOffset + rhrOffset
        return Resolved(
            value: min(Config.fiveKRangeMinutes.upperBound, max(Config.fiveKRangeMinutes.lowerBound, estimate)),
            measured: false
        )
    }

    private static func resolveRestingHR(
        _ input: Input,
        activity: AthleteOnboardingEngine.ActivityLevel
    ) -> Resolved<Double> {
        if let avg = averageRestingHR(input) { return Resolved(value: avg, measured: true) }
        let estimate: Double
        switch activity {
        case .sedentary: estimate = 74
        case .lightlyActive: estimate = 68
        case .moderatelyActive: estimate = 63
        case .veryActive: estimate = 57
        case .competitivePlayer: estimate = 52
        }
        return Resolved(value: estimate, measured: false)
    }

    private static func averageRestingHR(_ input: Input) -> Double? {
        let values = input.dailyHistory
            .sorted { $0.date > $1.date }
            .prefix(Config.rhrWindowDays)
            .compactMap(\.restingHeartRate)
            .filter { $0 > 30 && $0 < 120 }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    // MARK: - Powerlifting

    private struct Lifts {
        var total: Double
        var squat: Double
        var bench: Double
        var measuredCount: Int
    }

    private static func resolveLifts(
        _ input: Input,
        gender: AthleteOnboardingEngine.Gender,
        bodyweightLbs: Double,
        activity: AthleteOnboardingEngine.ActivityLevel
    ) -> Lifts {
        let ratio = gender == .male ? Config.maleRatio : Config.femaleRatio
        let squat = bestE1RM(input.liftSets, matching: ["squat"], excluding: ["split", "goblet"])
        let bench = bestE1RM(input.liftSets, matching: ["bench"], excluding: ["dumbbell"])
        let deadlift = bestE1RM(input.liftSets, matching: ["deadlift"], excluding: ["romanian", "rdl", "stiff"])

        let found: [(Double, Double)] = [(squat, ratio.squat), (bench, ratio.bench), (deadlift, ratio.deadlift)]
            .compactMap { lift, share in lift.map { ($0, share) } }

        let total: Double
        if found.isEmpty {
            // Interpolate from bodyweight × typical total multiple for the activity level.
            let multiple: Double
            switch (gender, activity) {
            case (.male, .sedentary): multiple = 2.0
            case (.male, .lightlyActive): multiple = 2.6
            case (.male, .moderatelyActive): multiple = 3.2
            case (.male, .veryActive): multiple = 3.8
            case (.male, .competitivePlayer): multiple = 4.6
            case (.female, .sedentary): multiple = 1.4
            case (.female, .lightlyActive): multiple = 1.8
            case (.female, .moderatelyActive): multiple = 2.3
            case (.female, .veryActive): multiple = 2.8
            case (.female, .competitivePlayer): multiple = 3.4
            }
            total = bodyweightLbs * multiple
        } else {
            // Scale the lifts we have up to a full total using reference shares.
            let liftSum = found.reduce(0) { $0 + $1.0 }
            let shareSum = found.reduce(0) { $0 + $1.1 }
            total = liftSum / shareSum
        }

        return Lifts(
            total: total,
            squat: squat ?? total * ratio.squat,
            bench: bench ?? total * ratio.bench,
            measuredCount: found.count
        )
    }

    /// Best estimated one-rep max (Epley: w × (1 + reps / 30)) for matching exercises.
    private static func bestE1RM(_ sets: [LiftSet], matching: [String], excluding: [String]) -> Double? {
        sets.compactMap { set -> Double? in
            let name = set.exerciseName.lowercased()
            guard matching.contains(where: name.contains),
                  !excluding.contains(where: name.contains),
                  set.weightLbs > 0, (1...Config.epleyMaxReps).contains(set.reps) else { return nil }
            return set.reps == 1 ? set.weightLbs : set.weightLbs * (1 + Double(set.reps) / 30)
        }.max()
    }

    // MARK: - Merge

    /// Averages male/female evaluations when sex is unknown; passes a single evaluation through.
    private static func average(_ evaluations: [WSLCompositeEvaluation]) -> WSLCompositeEvaluation {
        guard evaluations.count > 1, let first = evaluations.first else {
            return evaluations[0]
        }
        let composite = evaluations.map(\.compositeScore).reduce(0, +) / Double(evaluations.count)
        let sameShape = evaluations.allSatisfy { $0.subMetrics.count == first.subMetrics.count }
        let subMetrics: [SubMetric] = sameShape
            ? first.subMetrics.indices.map { index in
                let scores = evaluations.map { $0.subMetrics[index].score }
                let base = first.subMetrics[index]
                return SubMetric(
                    name: base.name.replacingOccurrences(of: " (Male)", with: ""),
                    rawValue: base.rawValue, unit: base.unit,
                    score: scores.reduce(0, +) / Double(scores.count),
                    weight: base.weight,
                    notes: base.notes + " (averaged across sexes)"
                )
            }
            : first.subMetrics
        let rank = WSLScaleRank.from(compositeScore: composite)
        return WSLCompositeEvaluation(
            sport: first.sport,
            gender: first.gender,
            compositeScore: composite,
            rank: rank,
            confidencePercentage: first.confidencePercentage,
            isProvisional: true,
            subMetrics: subMetrics,
            feedbackComment: feedback(for: rank)
        )
    }

    /// Same tier copy as the engine, for averaged results.
    private static func feedback(for rank: WSLScaleRank) -> String {
        switch rank {
        case .subPlayer: return "Sub-Player: Foundation phase needed. Focus on mobility and core."
        case .lowTierPlayer: return "Low Tier Player: Early motor competence. Linear overload will accelerate rank."
        case .midTierPlayer: return "Mid Tier Player: Well-rounded athleticism and conditioning balance."
        case .highTierPlayer: return "High Tier Player: Advanced performer with strong work capacity."
        case .goatLite: return "GOAT Lite: Elite regional powerhouse across force-velocity metrics."
        case .trueGoat: return "True GOAT: Apex performance in the 99th percentile composite."
        }
    }
}
