import Foundation

/// Maps workout types to body parts and scales yellow "worked" intensity.
enum WorkoutLoadMapper {
    /// Worked intensity decays toward zero over this many hours unless retrained.
    static let workedDecayHours: Double = 60

    /// Sore status auto-expires after this many days if the user does not clear it.
    static let soreExpiryDays: Int = 5

    /// Minimum hours before worked can escalate toward sore after heavy load.
    static let heavyLoadSoreHours: Double = 24

    static let typeToParts: [String: [BodyPart]] = [
        "running": [.leftQuad, .rightQuad, .leftHamstring, .rightHamstring, .leftCalf, .rightCalf, .glutes],
        "walking": [.leftQuad, .rightQuad, .leftCalf, .rightCalf],
        "cycling": [.leftQuad, .rightQuad, .glutes, .leftHamstring, .rightHamstring],
        "swimming": [.leftShoulder, .rightShoulder, .chest, .upperBack, .leftTricep, .rightTricep],
        "strength": [.chest, .upperBack, .leftShoulder, .rightShoulder, .leftQuad, .rightQuad, .glutes],
        "weightlifting": [.chest, .upperBack, .leftShoulder, .rightShoulder, .leftBicep, .rightBicep, .leftQuad, .rightQuad],
        "hiit": [.chest, .abs, .leftQuad, .rightQuad, .glutes, .leftShoulder, .rightShoulder],
        "yoga": [.lowerBack, .abs, .leftHip, .rightHip, .leftShoulder, .rightShoulder],
        "pilates": [.abs, .lowerBack, .glutes, .leftHip, .rightHip],
        "rowing": [.upperBack, .lowerBack, .leftBicep, .rightBicep, .leftQuad, .rightQuad],
        "basketball": [.leftKnee, .rightKnee, .leftCalf, .rightCalf, .leftQuad, .rightQuad],
        "soccer": [.leftQuad, .rightQuad, .leftHamstring, .rightHamstring, .leftCalf, .rightCalf],
        "tennis": [.leftShoulder, .rightShoulder, .leftForearm, .rightForearm, .leftCalf, .rightCalf],
        "push-ups": [.chest, .leftShoulder, .rightShoulder, .leftTricep, .rightTricep],
        "pushups": [.chest, .leftShoulder, .rightShoulder, .leftTricep, .rightTricep],
        "pull-ups": [.upperBack, .leftBicep, .rightBicep, .leftForearm, .rightForearm],
        "squats": [.leftQuad, .rightQuad, .glutes, .leftHamstring, .rightHamstring],
        "deadlift": [.lowerBack, .glutes, .leftHamstring, .rightHamstring],
        "other": [.chest, .leftQuad, .rightQuad],
    ]

    static func parts(forWorkoutType type: String) -> [BodyPart] {
        let key = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let exact = typeToParts[key] { return exact }
        if let fuzzy = typeToParts.first(where: { key.contains($0.key) }) {
            return fuzzy.value
        }
        return typeToParts["other"] ?? []
    }

    /// Intensity 0...1 from duration and optional average heart rate.
    static func intensity(durationMinutes: Double, averageHeartRate: Double?) -> Double {
        let durationFactor = min(1.0, durationMinutes / 60.0)
        let hrFactor: Double
        if let hr = averageHeartRate {
            // Map roughly 100–180 bpm into 0.3–1.0
            hrFactor = min(1.0, max(0.3, (hr - 90) / 90))
        } else {
            hrFactor = 0.6
        }
        return min(1.0, max(0.15, durationFactor * 0.55 + hrFactor * 0.45))
    }

    /// Decayed intensity after `hours` since last load. Zero after `workedDecayHours`.
    static func decayedIntensity(base: Double, hoursSince: Double) -> Double {
        guard hoursSince >= 0 else { return base }
        if hoursSince >= workedDecayHours { return 0 }
        let remaining = 1 - (hoursSince / workedDecayHours)
        return max(0, base * remaining)
    }

    /// Applies workout load. Never sets injured. Never overwrites injured with worked.
    static func applyWorkoutLoad(
        to records: inout [BodyPartStatusRecord],
        parts: [BodyPart],
        durationMinutes: Double,
        averageHeartRate: Double?,
        now: Date = .now
    ) {
        let bump = intensity(durationMinutes: durationMinutes, averageHeartRate: averageHeartRate)
        for part in parts {
            if let existing = records.first(where: { $0.part == part }) {
                if existing.status == .injured { continue }
                let merged = min(1.0, max(existing.intensity, bump))
                existing.intensity = merged
                existing.status = merged >= 0.85 && durationMinutes >= 45 ? .sore : .worked
                existing.sourceRaw = BodyStatusSource.autoWorkout.rawValue
                existing.updatedAt = now
                if existing.status == .worked || existing.status == .sore {
                    // keep startedAt if already sore/worked recently
                }
            } else {
                let status: BodyStatus = bump >= 0.85 && durationMinutes >= 45 ? .sore : .worked
                records.append(
                    BodyPartStatusRecord(
                        part: part,
                        status: status,
                        severity: status == .sore ? 2 : 1,
                        startedAt: now,
                        updatedAt: now,
                        source: .autoWorkout,
                        intensity: bump
                    )
                )
            }
        }
    }

    static func applyDecay(to records: inout [BodyPartStatusRecord], now: Date = .now) {
        for record in records {
            guard record.status == .worked || record.status == .sore else { continue }
            if record.status == .injured { continue }
            let hours = now.timeIntervalSince(record.updatedAt) / 3600
            if record.status == .worked {
                let decayed = decayedIntensity(base: record.intensity, hoursSince: hours)
                record.intensity = decayed
                if decayed <= 0.05 {
                    record.status = .healthy
                    record.intensity = 0
                }
            } else if record.status == .sore {
                let days = Calendar.current.dateComponents([.day], from: record.startedAt, to: now).day ?? 0
                if days >= soreExpiryDays {
                    record.status = .healthy
                    record.intensity = 0
                }
            }
        }
    }
}
