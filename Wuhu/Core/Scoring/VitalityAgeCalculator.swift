import Foundation

/// Deterministic local fallback and sanity check for Vitality Age.
///
/// Formula overview:
/// 1. Each metric is scored 0...1 against age-adjusted reference ranges (higher = healthier).
/// 2. Scores are weighted via `VitalityConfig.weights` and summed to a composite 0...1.
/// 3. Composite maps to an age offset: 0.5 → 0 years, 1.0 → −10 years, 0.0 → +10 years.
/// 4. Offset is clamped to ±`VitalityConfig.maxAgeOffset`.
/// Better stats never raise Vitality Age relative to worse stats (monotonic).
struct VitalityAgeCalculator: Sendable {
    struct Input: Equatable, Sendable {
        var chronologicalAge: Int
        var daysWithData: Int
        var avgRestingHR: Double?
        var avgSleepHours: Double?
        var sleepConsistencyStddevMinutes: Double?
        var avgSteps: Double?
        var avgWorkoutMinutes: Double?
        var avgHRV: Double?
    }

    struct Output: Equatable, Sendable {
        var vitalityAgeYears: Double?
        var deltaYears: Double?
        var insufficientData: Bool
        var metricScores: [String: Double]
        var drivers: [ScoreDriver]
    }

    func calculate(_ input: Input) -> Output {
        guard input.daysWithData >= VitalityConfig.minimumDaysOfData else {
            return Output(
                vitalityAgeYears: nil,
                deltaYears: nil,
                insufficientData: true,
                metricScores: [:],
                drivers: []
            )
        }

        var scores: [String: Double] = [:]
        var weightedSum = 0.0
        var weightTotal = 0.0
        let w = VitalityConfig.weights

        if let rhr = input.avgRestingHR {
            let target = VitalityConfig.restingHRTarget(age: input.chronologicalAge)
            // Lower resting HR is better. Score 1 at target−10, 0 at target+20.
            let score = clamp01((target + 20 - rhr) / 30)
            scores["resting_hr"] = score
            weightedSum += score * w.restingHeartRate
            weightTotal += w.restingHeartRate
        }

        if let sleep = input.avgSleepHours {
            let target = VitalityConfig.sleepHoursTarget
            let distance = abs(sleep - target)
            let score = clamp01(1 - distance / 3)
            scores["sleep_duration"] = score
            weightedSum += score * w.sleepDuration
            weightTotal += w.sleepDuration
        }

        if let consistency = input.sleepConsistencyStddevMinutes {
            // Lower stddev is better. 0 min → 1, 90+ min → 0.
            let score = clamp01(1 - consistency / 90)
            scores["sleep_consistency"] = score
            weightedSum += score * w.sleepConsistency
            weightTotal += w.sleepConsistency
        }

        if let steps = input.avgSteps {
            let score = clamp01(steps / VitalityConfig.stepsTarget)
            scores["steps"] = score
            weightedSum += score * w.steps
            weightTotal += w.steps
        }

        if let minutes = input.avgWorkoutMinutes {
            let score = clamp01(minutes / VitalityConfig.activeMinutesTarget)
            scores["active_load"] = score
            weightedSum += score * w.activeLoad
            weightTotal += w.activeLoad
        }

        if let hrv = input.avgHRV {
            let score = clamp01(hrv / VitalityConfig.hrvTargetMs)
            scores["hrv"] = score
            weightedSum += score * w.hrv
            weightTotal += w.hrv
        }

        guard weightTotal > 0 else {
            return Output(
                vitalityAgeYears: nil,
                deltaYears: nil,
                insufficientData: true,
                metricScores: scores,
                drivers: []
            )
        }

        let composite = weightedSum / weightTotal
        // 0.5 → 0 offset; each 0.05 away from 0.5 ≈ 1 year.
        let rawDelta = (0.5 - composite) * (VitalityConfig.maxAgeOffset / 0.5)
        let delta = min(VitalityConfig.maxAgeOffset, max(-VitalityConfig.maxAgeOffset, rawDelta))
        let vitalityAge = Double(input.chronologicalAge) + delta

        let drivers: [ScoreDriver] = scores
            .sorted { $0.value < $1.value }
            .prefix(4)
            .map { key, value in
                let effect = (0.5 - value) * 2
                return ScoreDriver(
                    metric: key,
                    effectYears: (effect * 10).rounded() / 10,
                    note: note(for: key, score: value)
                )
            }

        return Output(
            vitalityAgeYears: (vitalityAge * 10).rounded() / 10,
            deltaYears: (delta * 10).rounded() / 10,
            insufficientData: false,
            metricScores: scores,
            drivers: Array(drivers)
        )
    }

    func scoreResult(from input: Input) -> ScoreResult {
        let output = calculate(input)
        var result = ScoreResult(
            schemaVersion: 1,
            vitalityAge: VitalityAgeScore(
                years: output.vitalityAgeYears,
                deltaVsChronological: output.deltaYears,
                confidence: output.insufficientData ? "low" : "medium",
                drivers: output.drivers
            ),
            readiness: readiness(from: input, scores: output.metricScores),
            effort: effort(from: input),
            sleepScore: sleepScore(from: input, scores: output.metricScores),
            method: "Local VitalityAgeCalculator using weighted age-adjusted metric scores.",
            insufficientData: output.insufficientData,
            disclaimer: "Estimate for motivation only, not medical advice."
        )
        result.clamp()
        return result
    }

    private func readiness(from input: Input, scores: [String: Double]) -> LabeledScore {
        let hrv = scores["hrv"] ?? 0.5
        let rhr = scores["resting_hr"] ?? 0.5
        let sleep = scores["sleep_duration"] ?? 0.5
        let score = ((hrv * 0.4 + rhr * 0.35 + sleep * 0.25) * 100).rounded()
        let label: String
        switch score {
        case 80...: label = "great"
        case 65..<80: label = "good"
        case 45..<65: label = "fair"
        default: label = "low"
        }
        return LabeledScore(
            score: score,
            label: label,
            summary: "Based on resting HR, HRV, and sleep relative to targets."
        )
    }

    private func effort(from input: Input) -> EffortScore {
        let minutes = input.avgWorkoutMinutes ?? 0
        let score = min(21, (minutes / 60) * 12 + (input.avgSteps ?? 0) / 2000)
        return EffortScore(
            score: (score * 10).rounded() / 10,
            scaleMax: 21,
            summary: "Estimated from recent workout minutes and steps."
        )
    }

    private func sleepScore(from input: Input, scores: [String: Double]) -> LabeledScore {
        let duration = scores["sleep_duration"] ?? 0.5
        let consistency = scores["sleep_consistency"] ?? 0.5
        let score = ((duration * 0.65 + consistency * 0.35) * 100).rounded()
        return LabeledScore(
            score: score,
            label: nil,
            summary: "Duration and bedtime consistency versus targets."
        )
    }

    private func note(for metric: String, score: Double) -> String {
        if score >= 0.7 {
            return "\(metric) looks supportive of recovery."
        }
        if score >= 0.4 {
            return "\(metric) is near the middle of your reference range."
        }
        return "\(metric) is pulling Vitality Age upward."
    }

    private func clamp01(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}
