import Foundation

/// General wellness recovery tips for parts the user marked injured.
/// Not medical advice or diagnosis — encourage professional care when symptoms persist.
struct HealingTip: Equatable, Identifiable, Sendable {
    var id: String { title }
    var title: String
    var detail: String
}

struct HealingRecommendation: Equatable, Sendable {
    var part: BodyPart
    var summary: String
    var tips: [HealingTip]
    var seekCareWhen: String
}

enum HealingRecommendations {
    static let disclaimer =
        "These are general wellness ideas for the area you marked as injured. They are not a diagnosis or treatment plan. See a clinician or physical therapist for personal medical advice."

    static func recommendation(for part: BodyPart, severity: Int) -> HealingRecommendation {
        let tips = tips(for: part)
        let seek = seekCareCopy(severity: severity)
        return HealingRecommendation(
            part: part,
            summary: "You marked \(part.displayName) as injured. Ease load on this area and give recovery priority until it feels better.",
            tips: tips,
            seekCareWhen: seek
        )
    }

    private static func seekCareCopy(severity: Int) -> String {
        if severity >= 4 {
            return "Severity is high. Consider seeing a clinician or physical therapist soon, especially if pain is sharp, worsening, or limiting daily movement."
        }
        return "If this stays red for a week or more, worsens, or includes swelling, numbness, or instability, talk with a clinician or physical therapist."
    }

    private static func tips(for part: BodyPart) -> [HealingTip] {
        var tips = commonTips
        tips.append(contentsOf: regionTips(for: part))
        return tips
    }

    private static let commonTips: [HealingTip] = [
        HealingTip(
            title: "Protect and rest",
            detail: "Skip or swap workouts that load this part. Short walks and easy daily movement are usually fine if they do not increase pain."
        ),
        HealingTip(
            title: "Ease back in",
            detail: "When symptoms settle, return with shorter sessions and lower intensity. Stop if pain rises during or after activity."
        ),
        HealingTip(
            title: "Sleep and fuel",
            detail: "Steady sleep and protein-rich meals support tissue recovery. Keep hydration consistent through the day."
        ),
    ]

    private static func regionTips(for part: BodyPart) -> [HealingTip] {
        switch part {
        case .head, .neck:
            return [
                HealingTip(title: "Gentle neck mobility", detail: "Slow side-to-side and chin-tuck motions within a pain-free range. Avoid aggressive cracking or deep stretches."),
                HealingTip(title: "Screen posture", detail: "Raise screens to eye level and take brief posture breaks every 30–45 minutes."),
            ]
        case .leftShoulder, .rightShoulder:
            return [
                HealingTip(title: "Reduce overhead load", detail: "Pause presses and hanging work. Prefer supported rows or band pull-aparts if comfortable."),
                HealingTip(title: "Pendulum swings", detail: "Lean forward and let the arm hang; small circles can keep the joint moving without force."),
            ]
        case .chest:
            return [
                HealingTip(title: "Avoid heavy pressing", detail: "Skip bench and push-up variations until the area calms. Try light band openings for the front of the chest."),
            ]
        case .upperBack, .lowerBack:
            return [
                HealingTip(title: "Hip hinge carefully", detail: "Prefer short walks and supported positions. Avoid heavy deadlifts, twists, and long flexed sitting."),
                HealingTip(title: "Core bracing basics", detail: "Gentle dead-bug or bird-dog patterns can help if they stay pain-free. Stop if symptoms radiate."),
            ]
        case .abs:
            return [
                HealingTip(title: "Skip crunch volume", detail: "Avoid sit-ups and heavy loaded flexion. Focus on breathing and light walks."),
            ]
        case .leftBicep, .rightBicep, .leftTricep, .rightTricep:
            return [
                HealingTip(title: "Unload elbow flexors", detail: "Reduce curls, skull crushers, and high-rep gripping. Ice after activity if it feels soothing."),
            ]
        case .leftForearm, .rightForearm, .leftHand, .rightHand:
            return [
                HealingTip(title: "Grip and keyboard breaks", detail: "Loosen grip on tools and take micro-breaks from typing. Soft wrist-neutral stretches only if pain-free."),
            ]
        case .glutes, .leftHip, .rightHip:
            return [
                HealingTip(title: "Swap impact work", detail: "Replace sprints and deep squats with cycling or pool walking if comfortable."),
                HealingTip(title: "Gentle hip openers", detail: "Supported figure-four or short-range hip circles — never force into pain."),
            ]
        case .leftQuad, .rightQuad, .leftHamstring, .rightHamstring:
            return [
                HealingTip(title: "Cut hard running", detail: "Pause speed work and hills. Prefer flat easy walking until symptoms settle."),
                HealingTip(title: "Isometrics first", detail: "Light wall sits or bridge holds in a pain-free range can keep tissue active without strain."),
            ]
        case .leftKnee, .rightKnee:
            return [
                HealingTip(title: "Reduce deep knee bend", detail: "Avoid deep squats, lunges, and kneeling. Flat walking and partial range are safer early on."),
                HealingTip(title: "Support and ice", detail: "A soft brace for daily tasks and brief ice packs after activity may help comfort. Elevate when resting."),
            ]
        case .leftCalf, .rightCalf, .leftAnkle, .rightAnkle, .leftFoot, .rightFoot:
            return [
                HealingTip(title: "Limit plyometrics", detail: "Skip jumps, sprint starts, and uneven terrain. Supportive shoes for daily walking help."),
                HealingTip(title: "Ankle pumps", detail: "Pump the ankle and write the alphabet with your foot in a pain-free range to keep circulation moving."),
            ]
        }
    }
}
