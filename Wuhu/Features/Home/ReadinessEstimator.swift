import Foundation

/// Local readiness when LLM `ScoreResult.readiness` is unavailable.
///
/// Formula (0–100, higher = more recovered):
/// `100 − 38×lowerLoad − 16×upperLoad − 14×injuredParts − sleepPenalty`
/// where loads are mean engine load scores (0–1) for lower/upper multipliers groups.
enum ReadinessEstimator {
    static func score(
        wearResult: WearTearResult,
        sleepHours: Double?,
        scoreResult: ScoreResult?
    ) -> Int {
        if let readiness = scoreResult?.readiness?.score {
            return Int(min(100, max(0, readiness)).rounded())
        }

        let lowerParts: [BodyPart] = [
            .leftQuad, .rightQuad, .leftHamstring, .rightHamstring, .glutes,
            .leftHip, .rightHip, .leftKnee, .rightKnee, .leftCalf, .rightCalf,
            .leftAnkle, .rightAnkle, .leftFoot, .rightFoot, .lowerBack
        ]
        let upperParts: [BodyPart] = [
            .chest, .upperBack, .abs, .leftShoulder, .rightShoulder,
            .leftBicep, .rightBicep, .leftTricep, .rightTricep,
            .leftForearm, .rightForearm, .leftHand, .rightHand
        ]

        func meanLoad(_ parts: [BodyPart]) -> Double {
            let values = parts.compactMap { wearResult.loadByPart[$0] }
            guard !values.isEmpty else { return 0 }
            return values.reduce(0, +) / Double(values.count)
        }

        let lowerLoad = meanLoad(lowerParts)
        let upperLoad = meanLoad(upperParts)
        let injuredCount = Double(wearResult.wear.values.filter { $0 == .severe }.count)

        var value = 100.0
        value -= lowerLoad * 38
        value -= upperLoad * 16
        value -= injuredCount * 14

        if let sleep = sleepHours {
            if sleep < 4 {
                value -= 22
            } else if sleep < 6 {
                value -= 10
            } else if sleep < 7 {
                value -= 4
            }
        }

        return Int(min(100, max(0, value)).rounded())
    }
}
