import Foundation

enum NutritionSource: String, Equatable, Sendable {
    case myNetDiary
    case appleHealth
    case mock
    case unavailable
}

struct NutritionSummary: Equatable, Sendable {
    var todayCaloriesIn: Int?
    var weekCaloriesIn: Int?
    var proteinGrams: Int?
    var carbGrams: Int?
    var fatGrams: Int?
    var source: NutritionSource

    var macroLine: String? {
        guard proteinGrams != nil || carbGrams != nil || fatGrams != nil else { return nil }
        let protein = proteinGrams.map { "P \($0)g" } ?? "P —"
        let carbs = carbGrams.map { "C \($0)g" } ?? "C —"
        let fat = fatGrams.map { "F \($0)g" } ?? "F —"
        return "\(protein)  \(carbs)  \(fat)"
    }

    static let mock = NutritionSummary(
        todayCaloriesIn: 2_100,
        weekCaloriesIn: 14_200,
        proteinGrams: 140,
        carbGrams: 220,
        fatGrams: 70,
        source: .mock
    )
}

enum MyNetDiaryError: LocalizedError {
    case notConfigured
    case badResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "MyNetDiary is not configured."
        case .badResponse:
            return "MyNetDiary did not return a diary summary."
        }
    }
}

/// Reads a calorie-intake summary. Personal diary access is not a public MyNetDiary API.
protocol MyNetDiaryProviding: Sendable {
    func fetchSummary(days: Int) async throws -> NutritionSummary
}

enum MyNetDiaryConfiguration {
    static var apiKey: String { sanitized("MYNETDIARY_API_KEY") }
    static var baseURLString: String { sanitized("MYNETDIARY_BASE_URL") }
    static var userID: String { sanitized("MYNETDIARY_USER_ID") }

    static var isConfigured: Bool {
        !apiKey.isEmpty
    }

    static var baseURL: URL {
        let raw = baseURLString.isEmpty ? "https://api.mynetdiary.com" : baseURLString
        return URL(string: raw) ?? URL(string: "https://api.mynetdiary.com")!
    }

    private static func sanitized(_ key: String) -> String {
        let value = (Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty || value.hasPrefix("$(") || value.hasPrefix("your_") {
            return ""
        }
        return value
    }
}

/// Calls `GET {base}/v1/diary/days`. MyNetDiary does not publish this diary route;
/// it is the shape Wuhu accepts when a partner key or proxy is available.
struct MyNetDiaryAPIService: MyNetDiaryProviding {
    func fetchSummary(days: Int) async throws -> NutritionSummary {
        guard MyNetDiaryConfiguration.isConfigured else { throw MyNetDiaryError.notConfigured }
        var components = URLComponents(
            url: MyNetDiaryConfiguration.baseURL.appendingPathComponent("v1/diary/days"),
            resolvingAgainstBaseURL: false
        )
        var items = [URLQueryItem(name: "days", value: String(max(1, days)))]
        if !MyNetDiaryConfiguration.userID.isEmpty {
            items.append(URLQueryItem(name: "userId", value: MyNetDiaryConfiguration.userID))
        }
        components?.queryItems = items
        guard let url = components?.url else { throw MyNetDiaryError.badResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(MyNetDiaryConfiguration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(MyNetDiaryConfiguration.apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MyNetDiaryError.badResponse
        }
        let decoded = try JSONDecoder().decode(DiaryDaysResponse.self, from: data)
        return decoded.summary()
    }
}

private struct DiaryDaysResponse: Decodable {
    var days: [DiaryDay]

    func summary() -> NutritionSummary {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let todayDay = days.first { $0.date == today } ?? days.last
        let calories = days.compactMap(\.calories)
        return NutritionSummary(
            todayCaloriesIn: todayDay?.calories.map { Int($0.rounded()) },
            weekCaloriesIn: calories.isEmpty ? nil : Int(calories.reduce(0, +).rounded()),
            proteinGrams: todayDay?.protein.map { Int($0.rounded()) },
            carbGrams: todayDay?.carbs.map { Int($0.rounded()) },
            fatGrams: todayDay?.fat.map { Int($0.rounded()) },
            source: .myNetDiary
        )
    }
}

private struct DiaryDay: Decodable {
    var date: String
    var calories: Double?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
}
