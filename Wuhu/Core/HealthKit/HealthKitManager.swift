import Foundation
import HealthKit

/// Live HealthKit wrapper. Views should depend on `HealthDataProviding`, not this type.
final class HealthKitManager: HealthDataProviding, @unchecked Sendable {
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let rhr = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { types.insert(rhr) }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let active = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(active) }
        if let basal = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) { types.insert(basal) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        types.insert(HKObjectType.workoutType())
        if let dob = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) { types.insert(dob) }
        if let sex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) { types.insert(sex) }
        if let height = HKObjectType.quantityType(forIdentifier: .height) { types.insert(height) }
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) { types.insert(weight) }
        if let intake = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) { types.insert(intake) }
        if let protein = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) { types.insert(protein) }
        if let carbs = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) { types.insert(carbs) }
        if let fat = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) { types.insert(fat) }
        if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) { types.insert(distance) }
        return types
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthDataError.unavailable
        }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchDailyStats(for date: Date) async throws -> DailyStats {
        let history = try await fetchDailyHistory(days: 1, endingOn: date)
        guard let day = history.first else { throw HealthDataError.noData }
        return day
    }

    func fetchDailyHistory(days: Int) async throws -> [DailyStats] {
        try await fetchDailyHistory(days: days, endingOn: .now)
    }

    private func fetchDailyHistory(days: Int, endingOn end: Date) async throws -> [DailyStats] {
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: end)
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: endDay) else {
            return []
        }

        var results: [DailyStats] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let steps = await quiet { try await self.sumQuantity(.stepCount, unit: .count(), from: day, to: next) }
            let active = await quiet { try await self.sumQuantity(.activeEnergyBurned, unit: .kilocalorie(), from: day, to: next) }
            let basal = await quiet { try await self.sumQuantity(.basalEnergyBurned, unit: .kilocalorie(), from: day, to: next) }
            let intake = await quiet { try await self.sumQuantity(.dietaryEnergyConsumed, unit: .kilocalorie(), from: day, to: next) }
            let protein = await quiet { try await self.sumQuantity(.dietaryProtein, unit: .gram(), from: day, to: next) }
            let carbs = await quiet { try await self.sumQuantity(.dietaryCarbohydrates, unit: .gram(), from: day, to: next) }
            let fat = await quiet { try await self.sumQuantity(.dietaryFatTotal, unit: .gram(), from: day, to: next) }
            let distance = await quiet { try await self.sumQuantity(.distanceWalkingRunning, unit: .mile(), from: day, to: next) }
            let rhr = await quiet { try await self.averageQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), from: day, to: next) }
            let hrv = await quiet { try await self.averageQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), from: day, to: next) }
            let sleep = await quietOptional {
                if calendar.isDateInToday(day) {
                    let windowStart = calendar.date(byAdding: .hour, value: -18, to: day) ?? day
                    let windowEnd = calendar.date(byAdding: .hour, value: 12, to: day) ?? next
                    return try await self.fetchSleep(from: windowStart, to: windowEnd)
                }
                return try await self.fetchSleep(from: day, to: next)
            }
            let workouts = (try? await fetchWorkouts(from: day, to: next)) ?? []
            let workoutMinutes = workouts.reduce(0.0) { $0 + $1.durationMinutes }
            let latestHR: Double? = calendar.isDateInToday(day)
                ? await quiet { try await self.latestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), from: day, to: next) }
                : nil

            results.append(
                DailyStats(
                    date: day,
                    steps: steps.map { Int($0.rounded()) },
                    activeCalories: active,
                    restingCalories: basal,
                    restingHeartRate: rhr.map { $0.rounded() },
                    latestHeartRate: latestHR.map { $0.rounded() },
                    hrvSDNN: hrv.map { ($0 * 10).rounded() / 10 },
                    sleep: sleep,
                    workoutMinutes: workoutMinutes > 0 ? workoutMinutes : nil,
                    intakeCalories: intake,
                    proteinGrams: protein,
                    carbGrams: carbs,
                    fatGrams: fat,
                    distanceMiles: distance
                )
            )
        }
        return results
    }

    func fetchWorkouts(from start: Date, to end: Date) async throws -> [ImportedWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let samples: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthDataError.queryFailed(error.localizedDescription))
                    return
                }
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }

        let heartUnit = HKUnit.count().unitDivided(by: .minute())
        let heartType = HKQuantityType.quantityType(forIdentifier: .heartRate)
        return samples.map { workout in
            let stats = heartType.flatMap { workout.statistics(for: $0) }
            return ImportedWorkout(
                id: workout.uuid,
                type: workout.workoutActivityType.name,
                startDate: workout.startDate,
                durationMinutes: workout.duration / 60,
                calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                averageHeartRate: stats?.averageQuantity()?.doubleValue(for: heartUnit),
                maxHeartRate: stats?.maximumQuantity()?.doubleValue(for: heartUnit),
                distanceMiles: workout.totalDistance?.doubleValue(for: .mile())
            )
        }
    }

    func fetchProfile() async throws -> UserProfile {
        var profile = UserProfile()
        do {
            let components = try store.dateOfBirthComponents()
            if let date = Calendar.current.date(from: components) {
                profile.dateOfBirth = date
                profile.ageYears = Calendar.current.dateComponents([.year], from: date, to: .now).year
            }
        } catch {
            // Optional characteristic.
        }
        do {
            let sex = try store.biologicalSex().biologicalSex
            switch sex {
            case .female: profile.biologicalSex = "female"
            case .male: profile.biologicalSex = "male"
            case .other: profile.biologicalSex = "other"
            default: break
            }
        } catch {
            // Optional.
        }
        if let heightType = HKQuantityType.quantityType(forIdentifier: .height),
           let quantity = try? await latestQuantitySample(heightType) {
            profile.heightCm = quantity.doubleValue(for: .meterUnit(with: .centi))
        }
        if let massType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
           let quantity = try? await latestQuantitySample(massType) {
            profile.weightKg = quantity.doubleValue(for: .gramUnit(with: .kilo))
        }
        return profile
    }

    // MARK: - Queries

    /// A denied or missing type becomes nil so the rest of the day can still render.
    private func quiet(_ body: () async throws -> Double?) async -> Double? {
        do {
            return try await body()
        } catch {
            return nil
        }
    }

    private func quietOptional<T>(_ body: () async throws -> T?) async -> T? {
        do {
            return try await body()
        } catch {
            return nil
        }
    }

    private func sumQuantity(
        _ id: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from start: Date,
        to end: Date
    ) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error {
                    continuation.resume(throwing: HealthDataError.queryFailed(error.localizedDescription))
                    return
                }
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func averageQuantity(
        _ id: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from start: Date,
        to end: Date
    ) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, error in
                if let error {
                    continuation.resume(throwing: HealthDataError.queryFailed(error.localizedDescription))
                    return
                }
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func latestQuantity(
        _ id: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from start: Date,
        to end: Date
    ) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthDataError.queryFailed(error.localizedDescription))
                    return
                }
                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func latestQuantitySample(_ type: HKQuantityType) async throws -> HKQuantity? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthDataError.queryFailed(error.localizedDescription))
                    return
                }
                continuation.resume(returning: (samples?.first as? HKQuantitySample)?.quantity)
            }
            store.execute(query)
        }
    }

    private func fetchSleep(from start: Date, to end: Date) async throws -> SleepSummary? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthDataError.queryFailed(error.localizedDescription))
                    return
                }
                continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }
        guard !samples.isEmpty else { return nil }

        var deep: TimeInterval = 0
        var rem: TimeInterval = 0
        var core: TimeInterval = 0
        var awake: TimeInterval = 0
        var inBed: TimeInterval = 0
        var asleep: TimeInterval = 0
        var earliest: Date?
        var latest: Date?

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            earliest = minDate(earliest, sample.startDate)
            latest = maxDate(latest, sample.endDate)
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deep += duration; asleep += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                rem += duration; asleep += duration
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                core += duration; asleep += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awake += duration
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                inBed += duration
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                asleep += duration
            default:
                break
            }
        }

        let totalHours = asleep / 3600
        guard totalHours > 0 else { return nil }
        return SleepSummary(
            totalHours: (totalHours * 10).rounded() / 10,
            inBedHours: inBed > 0 ? ((inBed / 3600) * 10).rounded() / 10 : nil,
            deepHours: deep > 0 ? ((deep / 3600) * 10).rounded() / 10 : nil,
            remHours: rem > 0 ? ((rem / 3600) * 10).rounded() / 10 : nil,
            coreHours: core > 0 ? ((core / 3600) * 10).rounded() / 10 : nil,
            awakeHours: awake > 0 ? ((awake / 3600) * 10).rounded() / 10 : nil,
            bedtime: earliest,
            wakeTime: latest
        )
    }

    private func minDate(_ a: Date?, _ b: Date) -> Date {
        guard let a else { return b }
        return min(a, b)
    }

    private func maxDate(_ a: Date?, _ b: Date) -> Date {
        guard let a else { return b }
        return max(a, b)
    }
}

private extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "running"
        case .walking: return "walking"
        case .cycling: return "cycling"
        case .swimming: return "swimming"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "strength"
        case .highIntensityIntervalTraining: return "hiit"
        case .yoga: return "yoga"
        case .pilates: return "pilates"
        case .rowing: return "rowing"
        case .basketball: return "basketball"
        case .soccer: return "soccer"
        case .tennis: return "tennis"
        default: return "other"
        }
    }
}
