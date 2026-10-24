import Foundation

/// Fixed v1 body regions. Entity names in the 3D model must match `rawValue` exactly.
enum BodyPart: String, CaseIterable, Codable, Sendable, Identifiable {
    case head
    case neck
    case leftShoulder
    case rightShoulder
    case chest
    case upperBack
    case lowerBack
    case abs
    case leftBicep
    case rightBicep
    case leftTricep
    case rightTricep
    case leftForearm
    case rightForearm
    case leftHand
    case rightHand
    case glutes
    case leftHip
    case rightHip
    case leftQuad
    case rightQuad
    case leftHamstring
    case rightHamstring
    case leftKnee
    case rightKnee
    case leftCalf
    case rightCalf
    case leftAnkle
    case rightAnkle
    case leftFoot
    case rightFoot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .head: return "Head"
        case .neck: return "Neck"
        case .leftShoulder: return "Left Shoulder"
        case .rightShoulder: return "Right Shoulder"
        case .chest: return "Chest"
        case .upperBack: return "Upper Back"
        case .lowerBack: return "Lower Back"
        case .abs: return "Abs"
        case .leftBicep: return "Left Bicep"
        case .rightBicep: return "Right Bicep"
        case .leftTricep: return "Left Tricep"
        case .rightTricep: return "Right Tricep"
        case .leftForearm: return "Left Forearm"
        case .rightForearm: return "Right Forearm"
        case .leftHand: return "Left Hand"
        case .rightHand: return "Right Hand"
        case .glutes: return "Glutes"
        case .leftHip: return "Left Hip"
        case .rightHip: return "Right Hip"
        case .leftQuad: return "Left Quad"
        case .rightQuad: return "Right Quad"
        case .leftHamstring: return "Left Hamstring"
        case .rightHamstring: return "Right Hamstring"
        case .leftKnee: return "Left Knee"
        case .rightKnee: return "Right Knee"
        case .leftCalf: return "Left Calf"
        case .rightCalf: return "Right Calf"
        case .leftAnkle: return "Left Ankle"
        case .rightAnkle: return "Right Ankle"
        case .leftFoot: return "Left Foot"
        case .rightFoot: return "Right Foot"
        }
    }

    /// SF Symbol used so status is not color-only.
    var symbolName: String {
        switch self {
        case .head: return "brain.head.profile"
        case .neck: return "figure.stand"
        case .leftShoulder, .rightShoulder: return "figure.arms.open"
        case .chest, .upperBack, .lowerBack, .abs: return "figure.strengthtraining.functional"
        case .leftBicep, .rightBicep, .leftTricep, .rightTricep: return "dumbbell"
        case .leftForearm, .rightForearm, .leftHand, .rightHand: return "hand.raised"
        case .glutes, .leftHip, .rightHip: return "figure.strengthtraining.traditional"
        case .leftQuad, .rightQuad, .leftHamstring, .rightHamstring: return "figure.run"
        case .leftKnee, .rightKnee, .leftCalf, .rightCalf, .leftAnkle, .rightAnkle, .leftFoot, .rightFoot:
            return "shoeprints.fill"
        }
    }

    var isFrontFacing: Bool {
        switch self {
        case .upperBack, .lowerBack, .leftTricep, .rightTricep, .glutes,
             .leftHamstring, .rightHamstring, .leftCalf, .rightCalf:
            return false
        default:
            return true
        }
    }
}

enum BodyPartRegistry {
    static let allParts: [BodyPart] = BodyPart.allCases

    static func part(named name: String) -> BodyPart? {
        BodyPart(rawValue: name)
    }

    /// Every enum case must map to a unique entity name for 3D hit testing.
    static func entityNamesMatchEnum() -> Bool {
        Set(BodyPart.allCases.map(\.rawValue)).count == BodyPart.allCases.count
    }
}
