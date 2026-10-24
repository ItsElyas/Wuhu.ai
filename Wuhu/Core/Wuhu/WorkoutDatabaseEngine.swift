import Foundation
final class WorkoutDatabaseEngine {

    enum SessionType: String, Codable {
        case primaryLift = "Primary Lift / High CNS Power"
        case sportSpecificSkill = "Sport-Specific Conditioning / Skill"
        case secondaryVolume = "Secondary Strength / Hypertrophy"
        case activeRecovery = "Active Recovery & Soft Tissue Restoration"
        case completeRest = "Complete Rest & Parasympathetic Restoration"
    }

    struct ExercisePrescription: Codable {
        let sport: AthleteOnboardingEngine.SportDiscipline
        let phase: String
        let dayOfWeek: AthleteOnboardingEngine.DayOfWeek
        let sessionFocus: String
        let sessionType: SessionType
        let order: String
        let exercise: String
        let sets: Int
        let reps: String
        let intensity: String
        let restSeconds: Int
        let tempo: String
        let cue: String
    }

    enum ExerciseTier: String, Codable {
        case compoundStrength = "Compound Bilateral Max Strength"
        case unilateralStrength = "Unilateral Squat / Hinge"
        case ballisticPower = "Ballistic / Olympic Explosive"
        case hypertrophyPump = "Hypertrophy Mechanical Tension & Isolation"
        case enduranceAerobic = "Aerobic Base, Tempo & Interval Running"
        case accessoryRotational = "Accessory, Core & Rotational"
        case recoveryModality = "Restoration, Mobility & Recovery"
    }

    struct ProgressionRule: Codable {
        let tier: ExerciseTier
        let weeklyPercentIncreaseMin: Double
        let weeklyPercentIncreaseMax: Double
        let cadenceWeeks: Int
        let maxWeightJumpLbs: Double
        let overloadDescription: String
        let deloadFrequencyWeeks: Int
        let deloadVolumeDropPercent: Double
        let deloadIntensityDropPercent: Double
    }

    struct CompletedSetLog: Codable {
        let exerciseName: String
        let timestamp: Date
        let targetReps: Int
        let achievedReps: Int
        let rpeLogged: Double
        let loadUsedLbs: Double
    }

    struct DynamicWorkoutOutput {
        let original: ExercisePrescription
        let currentWeek: Int
        let prescribedSets: Int
        let prescribedReps: String
        let prescribedWeightLbs: Double
        let intensityLabel: String
        let overloadStatus: String
    }

    struct Repository {
        static let rules: [ProgressionRule] = [
            ProgressionRule(
                tier: .compoundStrength,
                weeklyPercentIncreaseMin: 0.02,
                weeklyPercentIncreaseMax: 0.025,
                cadenceWeeks: 1,
                maxWeightJumpLbs: 5.0,
                overloadDescription: "+2.0-2.5% load weekly if completed RPE <= 8.0",
                deloadFrequencyWeeks: 4,
                deloadVolumeDropPercent: 0.35,
                deloadIntensityDropPercent: 0.10
            ),
            ProgressionRule(
                tier: .hypertrophyPump,
                weeklyPercentIncreaseMin: 0.01,
                weeklyPercentIncreaseMax: 0.02,
                cadenceWeeks: 1,
                maxWeightJumpLbs: 5.0,
                overloadDescription: "Progress reps within bracket; add +1-2% load when top rep achieved",
                deloadFrequencyWeeks: 5,
                deloadVolumeDropPercent: 0.40,
                deloadIntensityDropPercent: 0.15
            ),
            ProgressionRule(
                tier: .enduranceAerobic,
                weeklyPercentIncreaseMin: 0.05,
                weeklyPercentIncreaseMax: 0.10,
                cadenceWeeks: 1,
                maxWeightJumpLbs: 0.0,
                overloadDescription: "+5-10% weekly distance/time duration cap to protect joints",
                deloadFrequencyWeeks: 4,
                deloadVolumeDropPercent: 0.30,
                deloadIntensityDropPercent: 0.0
            ),
            ProgressionRule(
                tier: .unilateralStrength,
                weeklyPercentIncreaseMin: 0.015,
                weeklyPercentIncreaseMax: 0.02,
                cadenceWeeks: 1,
                maxWeightJumpLbs: 2.5,
                overloadDescription: "+1.5-2.0% load or +1 rep/set every 1-2 weeks",
                deloadFrequencyWeeks: 4,
                deloadVolumeDropPercent: 0.30,
                deloadIntensityDropPercent: 0.10
            ),
            ProgressionRule(
                tier: .ballisticPower,
                weeklyPercentIncreaseMin: 0.0,
                weeklyPercentIncreaseMax: 0.01,
                cadenceWeeks: 2,
                maxWeightJumpLbs: 2.5,
                overloadDescription: "Prioritize bar velocity. +1% max every 2 weeks if RPE <= 7.0",
                deloadFrequencyWeeks: 4,
                deloadVolumeDropPercent: 0.40,
                deloadIntensityDropPercent: 0.05
            ),
            ProgressionRule(
                tier: .accessoryRotational,
                weeklyPercentIncreaseMin: 0.01,
                weeklyPercentIncreaseMax: 0.015,
                cadenceWeeks: 2,
                maxWeightJumpLbs: 2.5,
                overloadDescription: "Volume overload first (+1-2 reps); then add 1.5% load",
                deloadFrequencyWeeks: 4,
                deloadVolumeDropPercent: 0.30,
                deloadIntensityDropPercent: 0.10
            ),
            ProgressionRule(
                tier: .recoveryModality,
                weeklyPercentIncreaseMin: 0.0,
                weeklyPercentIncreaseMax: 0.0,
                cadenceWeeks: 1,
                maxWeightJumpLbs: 0.0,
                overloadDescription: "Restoration focus: parasympathetic down-regulation, zero load progression",
                deloadFrequencyWeeks: 4,
                deloadVolumeDropPercent: 0.0,
                deloadIntensityDropPercent: 0.0
            )
        ]

        static func buildWeeklyExerciseBank() -> [ExercisePrescription] {
            var bank: [ExercisePrescription] = []

            func add7DayPlan(
                sport: AthleteOnboardingEngine.SportDiscipline,
                phase: String,
                mon: (focus: String, type: SessionType, order: String, ex: String, sets: Int, reps: String, int: String, rest: Int, cue: String),
                tue: (focus: String, type: SessionType, order: String, ex: String, sets: Int, reps: String, int: String, rest: Int, cue: String),
                wed: (focus: String, type: SessionType, order: String, ex: String, sets: Int, reps: String, int: String, rest: Int, cue: String),
                thu: (focus: String, type: SessionType, order: String, ex: String, sets: Int, reps: String, int: String, rest: Int, cue: String),
                fri: (focus: String, type: SessionType, order: String, ex: String, sets: Int, reps: String, int: String, rest: Int, cue: String),
                sat: (focus: String, type: SessionType, order: String, ex: String, sets: Int, reps: String, int: String, rest: Int, cue: String),
                sun: (focus: String, type: SessionType, order: String, ex: String, sets: Int, reps: String, int: String, rest: Int, cue: String)
            ) {
                let daysData: [(AthleteOnboardingEngine.DayOfWeek, (focus: String, type: SessionType, order: String, ex: String, sets: Int, reps: String, int: String, rest: Int, cue: String))] = [
                    (.monday, mon), (.tuesday, tue), (.wednesday, wed), (.thursday, thu), (.friday, fri), (.saturday, sat), (.sunday, sun)
                ]
                for (day, d) in daysData {
                    bank.append(ExercisePrescription(
                        sport: sport, phase: phase, dayOfWeek: day, sessionFocus: d.focus, sessionType: d.type,
                        order: d.order, exercise: d.ex, sets: d.sets, reps: d.reps, intensity: d.int,
                        restSeconds: d.rest, tempo: d.type == .activeRecovery || d.type == .completeRest ? "Slow / Deep" : "Controlled", cue: d.cue
                    ))
                }
            }

            let standardActiveRecovery = (focus: "Active Recovery & Tissue Regeneration", type: SessionType.activeRecovery, order: "R1", ex: "Zone 1 Flush (Bike/Incline Walk) + Foam Roll & 90/90 Hip Flow", sets: 1, reps: "30-40 mins", int: "Heart Rate < 120 bpm", rest: 0, cue: "Stimulate blood flow, down-regulate nervous system, release tight myofascial chains")
            let standardCompleteRest = (focus: "Complete CNS & Neuromuscular Rest", type: SessionType.completeRest, order: "R0", ex: "Total Rest + Parasympathetic Box Breathing (4s In / 4s Hold / 4s Out)", sets: 1, reps: "15 mins", int: "0% Physical Strain", rest: 0, cue: "Zero joint loading. Prioritize 8+ hours sleep and nutrient-dense hydration")

            // 1. RUNNING
            add7DayPlan(
                sport: .running, phase: "Aerobic Base & Lactate Threshold",
                mon: ("Threshold Cruise Intervals & VO2 Max", .primaryLift, "A1", "Threshold Tempo Repeats (4 x 1 Mile)", 4, "1 Mile", "Zone 4 / RPE 8", 90, "Comfortably hard pace; relaxed shoulders, 175+ cadence"),
                tue: ("Easy Recovery Run & Strides", .secondaryVolume, "A1", "Easy Zone 2 Run + 4 x 100m Fast Strides", 1, "35 mins", "Zone 2", 60, "Flush legs; smooth fast turnover without straining"),
                wed: standardActiveRecovery,
                thu: ("Aerobic Hill Repeats & Calf Durability", .primaryLift, "A1", "Short Hill Sprints + Eccentric Calf Drops", 6, "45s hill + 15 drops", "RPE 8.5", 90, "Drive knees high; strengthen Achilles tendon"),
                fri: ("Mid-Distance Aerobic Flush Run", .secondaryVolume, "A1", "Steady Aerobic Base Run", 1, "40-45 mins", "Zone 2", 0, "Consistent rhythm; conversational nasal breathing"),
                sat: ("Long Aerobic Base Run & Capillary Density", .sportSpecificSkill, "A1", "Aerobic Base Long Run", 1, "60-75 mins", "Zone 2", 0, "Builds mitochondrial bed density and fuel efficiency"),
                sun: standardCompleteRest
            )

            // 2. POWERLIFTING
            add7DayPlan(
                sport: .powerlifting, phase: "Competition SBD Peaking",
                mon: ("Competition Squat & Bench Volume", .primaryLift, "A1", "Competition Low-Bar Squat + Paused Bench Press", 5, "3 + 3", "85% 1RM", 180, "IPF depth; motionless 1-second chest pause"),
                tue: ("Upper Body Accessory & Shoulder Health", .secondaryVolume, "A1", "Chest-Supported DB Rear Delt Flye + Skullcrushers", 4, "12 + 10", "RPE 7.5", 75, "Stabilize posterior shoulder shelf"),
                wed: standardActiveRecovery,
                thu: ("Competition Deadlift & Secondary Squat", .primaryLift, "A1", "Competition Deadlift + Pause Squats (2s hole)", 4, "2 + 4", "87.5% 1RM", 210, "Pull slack out of bar; pure concentric drive"),
                fri: ("Secondary Bench & Tricep Lockout Volume", .secondaryVolume, "A1", "Close Grip Bench Press + Barbell Seal Row", 4, "5 + 8", "77.5% 1RM", 120, "Reinforce lockout power and back rigidity"),
                sat: ("Hip Hinge Overload & Trunk Rigidity", .primaryLift, "A1", "Barbell Glute Bridge + Standing Cable Ab Crunch", 3, "6 + 12", "RPE 8", 90, "Strengthen deadlift lockout without spinal wear"),
                sun: standardCompleteRest
            )

            return bank
        }
    }

    private(set) var exerciseBank: [ExercisePrescription]
    private(set) var userLogs: [CompletedSetLog] = []

    init(customBank: [ExercisePrescription]? = nil) {
        self.exerciseBank = customBank ?? WorkoutPrescriptionLoader.loadFromBundle()
    }

    func logSession(exercise: String, targetReps: Int, achievedReps: Int, rpe: Double, loadLbs: Double) {
        let entry = CompletedSetLog(
            exerciseName: exercise,
            timestamp: Date(),
            targetReps: targetReps,
            achievedReps: achievedReps,
            rpeLogged: rpe,
            loadUsedLbs: loadLbs
        )
        userLogs.append(entry)
    }

    func classifyTier(for prescription: ExercisePrescription) -> ExerciseTier {
        if prescription.sessionType == .activeRecovery || prescription.sessionType == .completeRest {
            return .recoveryModality
        }
        // Every running session is aerobic work. (Name matching alone misfires: "Calf Drops" looked like
        // a calf-raise accessory and landed in the hypertrophy tier.)
        if prescription.sport == .running {
            return .enduranceAerobic
        }

        // Combined blocks ("Primary + Secondary") are classified by their LEAD movement. Matching the
        // whole string misfired: "...Ab Crunch" contains "run" (-> unbounded endurance progression on a
        // barbell accessory) and "Close Grip Bench Press + Barbell Seal Row" matched the row first.
        let full = prescription.exercise.lowercased()
        let lead = full.components(separatedBy: " + ").first ?? full
        func has(_ keywords: String...) -> Bool { keywords.contains { lead.contains($0) } }

        if has("clean", "jump", "slam", "hop") {
            return .ballisticPower
        } else if has("split squat", "lunge", "single-leg") {
            return .unilateralStrength
        } else if has("curl", "lateral raise", "seal row", "calf") {
            return .hypertrophyPump
        } else if has("competition", "squat", "deadlift", "bench") || (has("press") && !has("pallof")) {
            return .compoundStrength
        } else {
            return .accessoryRotational
        }
    }

    func generateOverloadPrescription(
        for prescription: ExercisePrescription,
        weekNumber: Int,
        baselineLoadLbs: Double = 100.0,
        wslScaleRank: WSLScaleRank = .midTierPlayer
    ) -> DynamicWorkoutOutput {
        let tier = classifyTier(for: prescription)

        if tier == .recoveryModality {
            return DynamicWorkoutOutput(
                original: prescription,
                currentWeek: weekNumber,
                prescribedSets: prescription.sets,
                prescribedReps: prescription.reps,
                prescribedWeightLbs: 0.0,
                intensityLabel: prescription.intensity,
                overloadStatus: "[wuhu.ai] RESTORATION MODALITY: Optimize parasympathetic recovery, zero weight overload."
            )
        }

        guard let rule = Repository.rules.first(where: { $0.tier == tier }) else {
            return DynamicWorkoutOutput(
                original: prescription,
                currentWeek: weekNumber,
                prescribedSets: prescription.sets,
                prescribedReps: prescription.reps,
                prescribedWeightLbs: baselineLoadLbs,
                intensityLabel: prescription.intensity,
                overloadStatus: "Standard Prescription"
            )
        }

        let wslScaleFactor: Double
        let wslNote: String
        switch wslScaleRank {
        case .subPlayer:
            wslScaleFactor = 0.65
            wslNote = "Sub-Player: Regressed volume/load (-35%) to protect tendons & build structural base."
        case .lowTierPlayer:
            wslScaleFactor = 0.85
            wslNote = "Low Tier Player: Controlled load (-15%) for form mastery."
        case .midTierPlayer:
            wslScaleFactor = 1.0
            wslNote = "Mid Tier Player: Standard athletic benchmark prescription."
        case .highTierPlayer:
            wslScaleFactor = 1.15
            wslNote = "High Tier Player: Elevated volume (+15%) matching proven work capacity."
        case .goatLite:
            wslScaleFactor = 1.25
            wslNote = "GOAT Lite: Elite loading (+25%) with high velocity intent."
        case .trueGoat:
            wslScaleFactor = 1.35
            wslNote = "True GOAT: Apex physical capacity (+35%). Maximum force output."
        }

        let adjustedBaseline = baselineLoadLbs * wslScaleFactor

        let isDeloadWeek = (weekNumber % rule.deloadFrequencyWeeks == 0)
        if isDeloadWeek {
            let reducedSets = max(1, Int(round(Double(prescription.sets) * (1.0 - rule.deloadVolumeDropPercent))))
            let reducedLoad = adjustedBaseline * (1.0 - rule.deloadIntensityDropPercent)
            return DynamicWorkoutOutput(
                original: prescription,
                currentWeek: weekNumber,
                prescribedSets: reducedSets,
                prescribedReps: prescription.reps,
                prescribedWeightLbs: reducedLoad,
                intensityLabel: "Deload Active (-10% Load)",
                overloadStatus: "[wuhu.ai] DELOAD MICROCYCLE: Volume -\(Int(rule.deloadVolumeDropPercent * 100))%, Load -\(Int(rule.deloadIntensityDropPercent * 100))%"
            )
        }

        // Progression cadence: a tier only steps its load every `cadenceWeeks` weeks (1 = every week).
        // This field was defined on every rule but never read, so 2-week tiers progressed weekly.
        let cadence = max(1, rule.cadenceWeeks)
        let isProgressionWeek = ((weekNumber - 1) % cadence == 0)

        let recentLog = userLogs.filter { $0.exerciseName.lowercased() == prescription.exercise.lowercased() }.last
        var percentIncrease = 0.0
        var status = "\(wslNote) Load Maintained (Consolidating motor patterns)"

        if let log = recentLog {
            if !isProgressionWeek {
                status = "\(wslNote) CADENCE HOLD: this tier steps load every \(cadence) weeks."
            } else if log.achievedReps >= log.targetReps && log.rpeLogged <= 7.5 {
                percentIncrease = rule.weeklyPercentIncreaseMax
                status = "\(wslNote) CLEARED (+): Optimal recovery (RPE \(log.rpeLogged)). Overload +\(String(format: "%.1f", percentIncrease * 100))%"
            } else if log.achievedReps >= log.targetReps && log.rpeLogged <= 8.5 {
                percentIncrease = rule.weeklyPercentIncreaseMin
                status = "\(wslNote) CLEARED: Target met (RPE \(log.rpeLogged)). Overload +\(String(format: "%.1f", percentIncrease * 100))%"
            } else if log.rpeLogged >= 9.0 || log.achievedReps < log.targetReps {
                percentIncrease = 0.0
                status = "\(wslNote) HOLD LOAD: Fatigue spike / RPE high (\(log.rpeLogged)). Form recovery required."
            }
        } else {
            let progressionSteps = max(0, weekNumber - 1) / cadence
            percentIncrease = min(Double(progressionSteps) * rule.weeklyPercentIncreaseMin, 0.08)
            status = "\(wslNote) Programmatic linear projection"
        }

        let rawWeightJump = adjustedBaseline * percentIncrease
        let cappedWeightJump = (rule.maxWeightJumpLbs > 0.0) ? min(rawWeightJump, rule.maxWeightJumpLbs) : rawWeightJump
        let finalWeight = adjustedBaseline + cappedWeightJump

        return DynamicWorkoutOutput(
            original: prescription,
            currentWeek: weekNumber,
            prescribedSets: prescription.sets,
            prescribedReps: prescription.reps,
            prescribedWeightLbs: finalWeight,
            intensityLabel: "\(prescription.intensity) (+\(String(format: "%.1f", cappedWeightJump)) lbs/vol)",
            overloadStatus: status
        )
    }

    func fetchWorkouts(for sport: AthleteOnboardingEngine.SportDiscipline) -> [ExercisePrescription] {
        return exerciseBank.filter { $0.sport == sport }
    }
}
