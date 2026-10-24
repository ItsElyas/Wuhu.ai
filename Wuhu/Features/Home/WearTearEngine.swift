import Foundation

/// One workout that can load body regions (HealthKit import or Workout Hub log).
struct WearWorkoutEvent: Sendable {
    var startDate: Date
    var type: String
    var durationMinutes: Double
    var averageHeartRate: Double?
    var musclesWorked: [BodyPart]
}

struct WearTearInput: Sendable {
    var bodyRecords: [BodyPartStatusRecord]
    var workouts: [WearWorkoutEvent]
    var sleepHoursLastNight: Double?
    var now: Date = .now
}

struct WearTearResult: Sendable {
    var wear: [BodyPart: WearLevel]
    var loadByPart: [BodyPart: Double]
}

/// Maps recent training load, user status, and sleep into Home / Body Map wear colors.
///
/// Manual verification (logic review, no xctest):
/// | Scenario | Expected wear |
/// |---|---|
/// | No workouts, no status, sleep 8h | All parts none (no overlay) |
/// | 60 min run yesterday, sleep 7h | Quads/hams/calves/glutes slight→high (legs weighted) |
/// | 45 min strength chest/shoulders | Chest/shoulders slight; legs none |
/// | Manual injured right knee | Right knee severe (red) regardless of load |
/// | Knee high + sleep 3h | Knee severe (high bumped +1 capped) |
/// | Same knee, next day no workout, sleep 8h | Knee high or slight (load decays ~35%/day) |
enum WearTearEngine {
    static let lookbackDays = 7
    static let sleepPenaltyThresholdHours = 4.0

    /// Lower body contributes more to systemic load than upper body.
    private static let regionMultiplier: [BodyPart: Double] = {
        var map: [BodyPart: Double] = [:]
        let lower: [BodyPart] = [
            .leftQuad, .rightQuad, .leftHamstring, .rightHamstring, .glutes,
            .leftHip, .rightHip, .leftKnee, .rightKnee, .leftCalf, .rightCalf,
            .leftAnkle, .rightAnkle, .leftFoot, .rightFoot, .lowerBack
        ]
        let upper: [BodyPart] = [
            .chest, .upperBack, .leftShoulder, .rightShoulder, .leftBicep, .rightBicep,
            .leftTricep, .rightTricep, .leftForearm, .rightForearm, .leftHand, .rightHand, .abs
        ]
        for part in lower { map[part] = 1.45 }
        for part in upper { map[part] = 0.85 }
        for part in BodyPart.allCases where map[part] == nil {
            map[part] = 1.0
        }
        return map
    }()

    static func compute(_ input: WearTearInput) -> WearTearResult {
        var load = loadScores(from: input.workouts, now: input.now)
        mergeManualStatus(into: &load, records: input.bodyRecords)

        var wear: [BodyPart: WearLevel] = [:]
        for part in BodyPart.allCases {
            let score = load[part] ?? 0
            wear[part] = level(from: score)
        }

        applyManualInjuryOverrides(to: &wear, records: input.bodyRecords)
        applySleepPenalty(to: &wear, sleepHours: input.sleepHoursLastNight)

        return WearTearResult(wear: wear, loadByPart: load)
    }

    /// Body Map tint: manual injury wins; otherwise derive status from wear level.
    static func bodyMapStatus(for part: BodyPart, wear: [BodyPart: WearLevel], record: BodyPartStatusRecord?) -> (BodyStatus, Double) {
        if let record, record.status == .injured {
            return (.injured, max(0.6, Double(record.severity) / 5.0))
        }
        switch wear[part] ?? .none {
        case .none:
            return (.healthy, 0)
        case .slight:
            return (.worked, 0.42)
        case .high:
            return (.sore, 0.72)
        case .severe:
            if let record, record.status == .sore {
                return (.sore, 0.95)
            }
            return (.sore, 0.9)
        }
    }

    static func color(for level: WearLevel) -> (BodyStatus, Double) {
        switch level {
        case .none: return (.healthy, 0)
        case .slight: return (.worked, 0.42)
        case .high: return (.sore, 0.72)
        case .severe: return (.sore, 0.92)
        }
    }

    // MARK: - Load

    private static func loadScores(from workouts: [WearWorkoutEvent], now: Date) -> [BodyPart: Double] {
        let calendar = Calendar.current
        guard let windowStart = calendar.date(byAdding: .day, value: -lookbackDays, to: now) else {
            return [:]
        }
        var load: [BodyPart: Double] = [:]

        for workout in workouts where workout.startDate >= windowStart {
            let parts = targetedParts(for: workout)
            let intensity = WorkoutLoadMapper.intensity(
                durationMinutes: workout.durationMinutes,
                averageHeartRate: workout.averageHeartRate
            )
            let daysAgo = max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: workout.startDate), to: calendar.startOfDay(for: now)).day ?? 0)
            let dayDecay = pow(0.68, Double(daysAgo))

            for part in parts {
                let weighted = intensity * (regionMultiplier[part] ?? 1.0) * dayDecay
                load[part] = min(1.0, (load[part] ?? 0) + weighted)
            }
        }
        return load
    }

    private static func targetedParts(for workout: WearWorkoutEvent) -> [BodyPart] {
        if !workout.musclesWorked.isEmpty {
            return workout.musclesWorked
        }
        return WorkoutLoadMapper.parts(forWorkoutType: workout.type)
    }

    private static func mergeManualStatus(into load: inout [BodyPart: Double], records: [BodyPartStatusRecord]) {
        for record in records where record.status != .healthy {
            if record.status == .injured { continue }
            let floor: Double
            switch record.status {
            case .sore:
                floor = 0.58
            case .worked:
                let decayed = WorkoutLoadMapper.decayedIntensity(base: record.intensity, hoursSince: record.hoursSinceUpdate)
                floor = max(0.12, decayed * 0.55)
            default:
                floor = 0
            }
            load[record.part] = max(load[record.part] ?? 0, floor)
        }
    }

    private static func level(from load: Double) -> WearLevel {
        if load <= 0.10 { return .none }
        if load <= 0.38 { return .slight }
        if load <= 0.68 { return .high }
        return .severe
    }

    private static func applyManualInjuryOverrides(to wear: inout [BodyPart: WearLevel], records: [BodyPartStatusRecord]) {
        for record in records where record.status == .injured {
            wear[record.part] = .severe
        }
    }

    private static func applySleepPenalty(to wear: inout [BodyPart: WearLevel], sleepHours: Double?) {
        guard let sleepHours, sleepHours < sleepPenaltyThresholdHours else { return }
        for part in BodyPart.allCases {
            guard let current = wear[part], current != .none else { continue }
            wear[part] = bump(current)
        }
    }

    private static func bump(_ level: WearLevel) -> WearLevel {
        switch level {
        case .none: return .none
        case .slight: return .high
        case .high: return .severe
        case .severe: return .severe
        }
    }
}
