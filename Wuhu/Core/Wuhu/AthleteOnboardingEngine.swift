import Foundation

/// Running and powerlifting onboarding + multi-factor WSL composite (R2). No CLI.
enum AthleteOnboardingEngine {

    enum Gender: String, Codable, CaseIterable, Sendable {
        case male = "Male"
        case female = "Female"
    }

    enum ActivityLevel: String, Codable, CaseIterable, Sendable {
        case sedentary = "Sedentary (Desk job, minimal activity)"
        case lightlyActive = "Lightly Active (1-3 light sessions/week)"
        case moderatelyActive = "Moderately Active (3-5 sport/gym sessions/week)"
        case veryActive = "Very Active (6-7 intense sessions/week)"
        case competitivePlayer = "Competitive Player (2x day training / collegiate / pro)"
    }

    enum SportDiscipline: String, Codable, CaseIterable, Sendable {
        case running = "Running"
        case powerlifting = "Powerlifting"
    }

    enum PrimaryGoal: String, Codable, CaseIterable, Sendable {
        case explosivePower = "Explosive Power & Rate of Force Development"
        case maxStrength = "Maximal Strength & 1RM Progression"
        case hypertrophy = "Hypertrophy & Muscle Volume (Aesthetics)"
        case aerobicEndurance = "Aerobic Base, VO2 Max & Mileage Capacity"
        case speedAgilityDecel = "Sprint Acceleration & Deceleration Durability"
        case jointResilience = "Rotator Cuff & Joint Durability"
        case anaerobicConditioning = "Lactate Tolerance & Alactic Capacity"
    }

    enum DayOfWeek: String, Codable, CaseIterable, Sendable {
        case monday = "Monday"
        case tuesday = "Tuesday"
        case wednesday = "Wednesday"
        case thursday = "Thursday"
        case friday = "Friday"
        case saturday = "Saturday"
        case sunday = "Sunday"

        static func from(date: Date, calendar: Calendar = .current) -> DayOfWeek {
            switch calendar.component(.weekday, from: date) {
            case 1: return .sunday
            case 2: return .monday
            case 3: return .tuesday
            case 4: return .wednesday
            case 5: return .thursday
            case 6: return .friday
            default: return .saturday
            }
        }

        var shortLabel: String { rawValue }
    }

    struct PlayerProfile: Codable, Sendable, Equatable {
        var name: String
        var gender: Gender
        var age: Int
        var heightInches: Double
        var weightLbs: Double
        var activityLevel: ActivityLevel
        var selectedSport: SportDiscipline
        var goals: [PrimaryGoal]
        var wslEvaluation: WSLCompositeEvaluation?

        var formattedHeight: String {
            let feet = Int(heightInches) / 12
            let inches = Int(heightInches) % 12
            return "\(feet)'\(inches)\""
        }

        var bmi: Double {
            guard heightInches > 0 else { return 0 }
            return (weightLbs / (heightInches * heightInches)) * 703.0
        }

        var weightKg: Double { weightLbs * 0.45359237 }
    }

    enum OnboardingError: Error, LocalizedError {
        case invalidName
        case invalidAge
        case invalidHeight
        case invalidWeight
        case noGoalsSelected

        var errorDescription: String? {
            switch self {
            case .invalidName: return "Player name cannot be blank."
            case .invalidAge: return "Age must be between 10 and 100."
            case .invalidHeight: return "Height must be between 36 and 96 inches."
            case .invalidWeight: return "Weight must be between 50 and 500 lbs."
            case .noGoalsSelected: return "Select at least one development goal."
            }
        }
    }

    static func defaultGoals(for sport: SportDiscipline) -> [PrimaryGoal] {
        switch sport {
        case .running: return [.aerobicEndurance, .anaerobicConditioning]
        case .powerlifting: return [.maxStrength, .jointResilience]
        }
    }

    static func evaluateCompositeWSL(
        sport: SportDiscipline,
        gender: Gender,
        age: Int,
        bodyweightLbs: Double,
        heightInches: Double,
        primaryVal: Double,
        subMetricA: Double?,
        subMetricB: Double?
    ) -> WSLCompositeEvaluation {
        var subMetrics: [SubMetric] = []
        var optionalInputsUsed = 0

        switch sport {
        case .running:
            let fiveK = primaryVal
            let fiveKScore: Double
            if gender == .male {
                if fiveK >= 32.0 { fiveKScore = 1.0 }
                else if fiveK >= 26.0 { fiveKScore = 2.0 }
                else if fiveK >= 21.0 { fiveKScore = 3.0 }
                else if fiveK >= 18.0 { fiveKScore = 4.0 }
                else if fiveK >= 15.5 { fiveKScore = 5.0 }
                else { fiveKScore = 6.0 }
            } else {
                if fiveK >= 35.5 { fiveKScore = 1.0 }
                else if fiveK >= 29.0 { fiveKScore = 2.0 }
                else if fiveK >= 23.5 { fiveKScore = 3.0 }
                else if fiveK >= 20.0 { fiveKScore = 4.0 }
                else if fiveK >= 17.2 { fiveKScore = 5.0 }
                else { fiveKScore = 6.0 }
            }
            subMetrics.append(SubMetric(
                name: "5K Race Time (\(gender.rawValue))", rawValue: fiveK, unit: "min",
                score: fiveKScore, weight: 0.40, notes: "WMA sex-calibrated lactate threshold velocity"
            ))

            let ageFactor: Double
            if age <= 25 { ageFactor = 1.0 }
            else if age <= 35 { ageFactor = 0.98 }
            else if age <= 45 { ageFactor = 0.92 }
            else if age <= 55 { ageFactor = 0.85 }
            else { ageFactor = 0.77 }

            let ageAdjustedTime = fiveK * ageFactor
            let ageGradeScore: Double
            if gender == .male {
                if ageAdjustedTime >= 30.0 { ageGradeScore = 1.0 }
                else if ageAdjustedTime >= 24.5 { ageGradeScore = 2.0 }
                else if ageAdjustedTime >= 20.0 { ageGradeScore = 3.0 }
                else if ageAdjustedTime >= 17.0 { ageGradeScore = 4.0 }
                else if ageAdjustedTime >= 15.0 { ageGradeScore = 5.0 }
                else { ageGradeScore = 6.0 }
            } else {
                if ageAdjustedTime >= 33.5 { ageGradeScore = 1.0 }
                else if ageAdjustedTime >= 27.5 { ageGradeScore = 2.0 }
                else if ageAdjustedTime >= 22.5 { ageGradeScore = 3.0 }
                else if ageAdjustedTime >= 19.0 { ageGradeScore = 4.0 }
                else if ageAdjustedTime >= 16.8 { ageGradeScore = 5.0 }
                else { ageGradeScore = 6.0 }
            }
            subMetrics.append(SubMetric(
                name: "Age & Sex Graded Factor", rawValue: ageAdjustedTime, unit: "adj-min",
                score: ageGradeScore, weight: 0.35,
                notes: "World Masters Athletics standard for \(gender.rawValue) age \(age)"
            ))

            if let rhr = subMetricA {
                optionalInputsUsed += 1
                let rhrScore: Double
                if gender == .male {
                    if rhr > 75.0 { rhrScore = 1.0 }
                    else if rhr > 64.0 { rhrScore = 2.0 }
                    else if rhr > 54.0 { rhrScore = 3.0 }
                    else if rhr > 46.0 { rhrScore = 4.0 }
                    else if rhr > 40.0 { rhrScore = 5.0 }
                    else { rhrScore = 6.0 }
                } else {
                    if rhr > 78.0 { rhrScore = 1.0 }
                    else if rhr > 68.0 { rhrScore = 2.0 }
                    else if rhr > 58.0 { rhrScore = 3.0 }
                    else if rhr > 50.0 { rhrScore = 4.0 }
                    else if rhr > 44.0 { rhrScore = 5.0 }
                    else { rhrScore = 6.0 }
                }
                subMetrics.append(SubMetric(
                    name: "Resting Heart Rate", rawValue: rhr, unit: "bpm",
                    score: rhrScore, weight: 0.25, notes: "Autonomic tone & stroke volume"
                ))
            }

        case .powerlifting:
            let total = primaryVal
            let bwKg = max(40.0, bodyweightLbs * 0.45359237)

            let rawScore: Double
            if gender == .male {
                if total < 600.0 { rawScore = 1.0 }
                else if total < 900.0 { rawScore = 2.0 }
                else if total < 1200.0 { rawScore = 3.0 }
                else if total < 1500.0 { rawScore = 4.0 }
                else if total < 1800.0 { rawScore = 5.0 }
                else { rawScore = 6.0 }
            } else {
                if total < 400.0 { rawScore = 1.0 }
                else if total < 600.0 { rawScore = 2.0 }
                else if total < 800.0 { rawScore = 3.0 }
                else if total < 1000.0 { rawScore = 4.0 }
                else if total < 1200.0 { rawScore = 5.0 }
                else { rawScore = 6.0 }
            }
            subMetrics.append(SubMetric(
                name: "Raw SBD Total (\(gender.rawValue))", rawValue: total, unit: "lbs",
                score: rawScore, weight: 0.35,
                notes: "Absolute load for biological \(gender.rawValue)"
            ))

            let totalKg = total * 0.45359237
            let denom: Double
            if gender == .male {
                let boundedBw = min(210.0, max(40.0, bwKg))
                denom = (-0.0000010930 * pow(boundedBw, 4)) + (0.0007391293 * pow(boundedBw, 3))
                    + (-0.1918759221 * pow(boundedBw, 2)) + (24.0900756 * boundedBw) - 307.75076
            } else {
                let boundedBw = min(150.0, max(40.0, bwKg))
                denom = (-0.0000010706 * pow(boundedBw, 4)) + (0.0005158568 * pow(boundedBw, 3))
                    + (-0.1126655495 * pow(boundedBw, 2)) + (13.6175032 * boundedBw) - 57.96288
            }
            let dotsCoeff = denom > 0 ? (500.0 / denom) : 0.65
            let dotsScoreRaw = totalKg * dotsCoeff
            let dotsScore: Double
            if dotsScoreRaw < 220.0 { dotsScore = 1.0 }
            else if dotsScoreRaw < 310.0 { dotsScore = 2.0 }
            else if dotsScoreRaw < 390.0 { dotsScore = 3.0 }
            else if dotsScoreRaw < 460.0 { dotsScore = 4.0 }
            else if dotsScoreRaw < 525.0 { dotsScore = 5.0 }
            else { dotsScore = 6.0 }
            subMetrics.append(SubMetric(
                name: "IPF DOTS Score (\(gender.rawValue))", rawValue: dotsScoreRaw, unit: "pts",
                score: dotsScore, weight: 0.45,
                notes: "IPF \(gender.rawValue) polynomial curve"
            ))

            if let squat = subMetricA, let bench = subMetricB, squat > 0, bench > 0, squat + bench < total {
                optionalInputsUsed += 2
                let deadlift = total - squat - bench
                let ref = (gender == .male) ? (s: 0.35, b: 0.24, d: 0.41) : (s: 0.36, b: 0.20, d: 0.44)
                let deviation = abs(squat / total - ref.s) + abs(bench / total - ref.b) + abs(deadlift / total - ref.d)
                let penalty = min(1.5, max(0.0, (deviation - 0.06) * 10.0))
                let levelScore = (rawScore * 0.35 + dotsScore * 0.45) / 0.80
                let pct = { (x: Double) in Int((x * 100).rounded()) }
                subMetrics.append(SubMetric(
                    name: "SBD Structural Ratio", rawValue: deviation * 100.0, unit: "% off ref",
                    score: max(1.0, levelScore - penalty), weight: 0.20,
                    notes: "S/B/D = \(pct(squat / total))/\(pct(bench / total))/\(pct(deadlift / total))%"
                ))
            }
        }

        let totalWeight = subMetrics.reduce(0.0) { $0 + $1.weight }
        let normalized = subMetrics.map {
            SubMetric(
                name: $0.name, rawValue: $0.rawValue, unit: $0.unit, score: $0.score,
                weight: totalWeight > 0 ? $0.weight / totalWeight : $0.weight, notes: $0.notes
            )
        }
        let weightedSum = normalized.reduce(0.0) { $0 + ($1.score * $1.weight) }
        let finalRank = WSLScaleRank.from(compositeScore: weightedSum)

        let optionalSlots = sport == .running ? 1 : 2
        let confidence: Int
        if optionalInputsUsed == 0 { confidence = 40 }
        else if optionalInputsUsed >= optionalSlots { confidence = 100 }
        else { confidence = 70 }
        let isProvisional = confidence < 70

        let comment: String
        switch finalRank {
        case .subPlayer:
            comment = "Sub-Player: Foundation phase needed. Focus on mobility and core."
        case .lowTierPlayer:
            comment = "Low Tier Player: Early motor competence. Linear overload will accelerate rank."
        case .midTierPlayer:
            comment = "Mid Tier Player: Well-rounded athleticism and conditioning balance."
        case .highTierPlayer:
            comment = "High Tier Player: Advanced performer with strong work capacity."
        case .goatLite:
            comment = "GOAT Lite: Elite regional powerhouse across force-velocity metrics."
        case .trueGoat:
            comment = "True GOAT: Apex performance in the 99th percentile composite."
        }

        return WSLCompositeEvaluation(
            sport: sport,
            gender: gender,
            compositeScore: weightedSum,
            rank: finalRank,
            confidencePercentage: confidence,
            isProvisional: isProvisional,
            subMetrics: normalized,
            feedbackComment: comment
        )
    }

    static func makeProfile(
        name: String,
        gender: Gender,
        age: Int,
        heightInches: Double,
        weightLbs: Double,
        activityLevel: ActivityLevel,
        selectedSport: SportDiscipline,
        wslEvaluation: WSLCompositeEvaluation?
    ) throws -> PlayerProfile {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw OnboardingError.invalidName }
        guard (10...100).contains(age) else { throw OnboardingError.invalidAge }
        guard heightInches > 36, heightInches < 96 else { throw OnboardingError.invalidHeight }
        guard weightLbs > 50, weightLbs < 500 else { throw OnboardingError.invalidWeight }
        return PlayerProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            gender: gender,
            age: age,
            heightInches: heightInches,
            weightLbs: weightLbs,
            activityLevel: activityLevel,
            selectedSport: selectedSport,
            goals: defaultGoals(for: selectedSport),
            wslEvaluation: wslEvaluation
        )
    }
}
