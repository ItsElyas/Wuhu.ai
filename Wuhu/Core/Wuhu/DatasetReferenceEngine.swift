import Foundation

struct DatasetCitation: Codable, Sendable {
    let discipline: AthleteOnboardingEngine.SportDiscipline
    let datasetTitle: String
    let sourceAuthority: String
    let licenseOrAccess: String
    let metricsDerived: [String]
    let empiricalApplication: String
    let sexSpecificStandardNote: String
}

enum DatasetReferenceEngine {
    static let sharedCitations: [DatasetCitation] = [
        DatasetCitation(
            discipline: .powerlifting,
            datasetTitle: "OpenPowerlifting Community Dataset (2.8M+ attempts) & IPF DOTS Revision",
            sourceAuthority: "International Powerlifting Federation (IPF) / OpenPowerlifting.org / BVDK",
            licenseOrAccess: "Open Data Commons Open Database License (ODbL)",
            metricsDerived: [
                "Male 4th-Order Polynomial Constants",
                "Female 4th-Order Polynomial Constants",
                "Bodyweight-Normalized Strength Distribution",
            ],
            empiricalApplication: """
            Applies sex-differentiated 4th-order polynomial denominators to normalize total barbell load \
            against bodyweight, accounting for biological differences in cross-sectional muscle area and \
            skeletal frame between men and women.
            """,
            sexSpecificStandardNote: """
            Male polynomial range (40-210kg): P(x) = -307.75076 + 24.0900756x - 0.1918759221x^2 + \
            0.0007391293x^3 - 0.0000010930x^4. Female polynomial range (40-150kg): P(x) = -57.96288 + \
            13.6175032x - 0.1126655495x^2 + 0.0005158568x^3 - 0.0000010706x^4.
            """
        ),
        DatasetCitation(
            discipline: .running,
            datasetTitle: "World Masters Athletics (WMA) Age & Sex-Graded Pacing Tables & Runalytics",
            sourceAuthority: "World Masters Athletics (WMA) & USATF Masters Track & Field",
            licenseOrAccess: "Creative Commons Attribution-NonCommercial (CC BY-NC 4.0)",
            metricsDerived: [
                "Male 5K Open-Class Base Standard (12:35.36)",
                "Female 5K Open-Class Base Standard (14:06.62)",
                "Sex-Stratified Masters Age Decay Curves",
            ],
            empiricalApplication: """
            Calibrates aerobic velocity by normalizing for baseline differences in hemoglobin concentration, \
            heart stroke volume, and VO2max between biological males and females.
            """,
            sexSpecificStandardNote: """
            WMA standards account for physiological dimorphism: female open-class 5K is 14:06.62 vs male \
            12:35.36. The WSL Scale normalizes both for equitable tier ranking.
            """
        ),
    ]

    static func formattedCitationsForLLM(
        for discipline: AthleteOnboardingEngine.SportDiscipline,
        gender: AthleteOnboardingEngine.Gender
    ) -> String {
        let matching = sharedCitations.filter { $0.discipline == discipline }
        guard !matching.isEmpty else { return "[No dataset cited for this sport]" }

        var buffer = "=== WUHU.AI GROUND TRUTH EMPIRICAL DATASETS (\(gender.rawValue.uppercased()) CALIBRATED) ===\n"
        for citation in matching {
            buffer += "Dataset: \(citation.datasetTitle)\n"
            buffer += "Authority: \(citation.sourceAuthority) (\(citation.licenseOrAccess))\n"
            buffer += "Metrics Derived: \(citation.metricsDerived.joined(separator: ", "))\n"
            buffer += "Scientific Application: \(citation.empiricalApplication)\n"
            buffer += "Sex Differential Standards: \(citation.sexSpecificStandardNote)\n\n"
        }
        return buffer
    }
}
