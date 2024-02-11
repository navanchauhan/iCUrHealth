//
//  HealthData.swift
//  iCUrHealth
//
//  Created by Navan Chauhan on 2/10/24.
//

// Some code is part of the Stanford HealthGPT project
// SPDX-FileCopyrightText: 2023 Stanford University & Project Contributors
// SPDX-License-Identifier: MIT

import Foundation
import HealthKit

extension Date {
    /// - Returns: A `Date` object representing the start of the current day.
    static func startOfDay() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// - Returns: A `Date` object representing the start of the day exactly two weeks ago.
    func twoWeeksAgoStartOfDay() -> Date {
        Calendar.current.date(byAdding: DateComponents(day: -14), to: Date.startOfDay()) ?? Date()
    }
}

struct ScreenTimeData: Decodable {
    let screenTimeTotal: [Double]
    let screenTimeSocial: [Double]
}

struct HealthData: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var steps: Double?
    var activeEnergy: Double?
    var exerciseMinutes: Double?
    var bodyWeight: Double?
    var sleepHours: Double?
    var minutesInDaylight: Double?
    var screenTimeSocialMedia: Double?
    var screenTimeTotal: Double?
}

enum HealthDataFetcherError: Error {
    case healthDataNotAvailable
    case invalidObjectType
    case resultsNotFound
    case authorizationFailed
}

class HealthDataFetcher {
    private let healthStore = HKHealthStore()
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HKError(.errorHealthDataUnavailable)
        }

        let types: Set = [
            HKQuantityType(.stepCount),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.bodyMass),
            HKQuantityType(.heartRate),
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.timeInDaylight),
            HKQuantityType(.restingHeartRate)
        ]

        try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: types)
    }

    func fetchLastTwoWeeksQuantityData(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        options: HKStatisticsOptions
    ) async throws -> [Double] {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            throw HealthDataFetcherError.invalidObjectType
        }

        let predicate = createLastTwoWeeksPredicate()

        let quantityLastTwoWeeks = HKSamplePredicate.quantitySample(
            type: quantityType,
            predicate: predicate
        )

        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: quantityLastTwoWeeks,
            options: options,
            anchorDate: Date.startOfDay(),
            intervalComponents: DateComponents(day: 1)
        )

        let quantityCounts = try await query.result(for: healthStore)

        var dailyData = [Double]()

        quantityCounts.enumerateStatistics(
            from: Date().twoWeeksAgoStartOfDay(),
            to: Date.startOfDay()
        ) { statistics, _ in
            if let quantity = statistics.sumQuantity() {
                dailyData.append(quantity.doubleValue(for: unit))
            } else {
                dailyData.append(0)
            }
        }

        return dailyData
    }

    func fetchLastTwoWeeksStepCount() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(
            for: .stepCount,
            unit: HKUnit.count(),
            options: [.cumulativeSum]
        )
    }
    
    func fetchLastTwoWeeksTimeinDaylight() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(for: .timeInDaylight, unit: HKUnit.minute(), options: [.cumulativeSum])
    }

    func fetchLastTwoWeeksActiveEnergy() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(
            for: .activeEnergyBurned,
            unit: HKUnit.largeCalorie(),
            options: [.cumulativeSum]
        )
    }

    func fetchLastTwoWeeksExerciseTime() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(
            for: .appleExerciseTime,
            unit: .minute(),
            options: [.cumulativeSum]
        )
    }

    func fetchLastTwoWeeksBodyWeight() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(
            for: .bodyMass,
            unit: .pound(),
            options: [.discreteAverage]
        )
    }

    func fetchLastTwoWeeksHeartRate() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(
            for: .heartRate,
            unit: .count(),
            options: [.discreteAverage]
        )
    }

    func fetchLastTwoWeeksSleep() async throws -> [Double] {
        var dailySleepData: [Double] = []
        
        // We go through all possible days in the last two weeks.
        for day in -14..<0 {
            // We start the calculation at 3 PM the previous day to 3 PM on the day in question.
            guard let startOfSleepDay = Calendar.current.date(byAdding: DateComponents(day: day - 1), to: Date.startOfDay()),
                  let startOfSleep = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: startOfSleepDay),
                  let endOfSleepDay = Calendar.current.date(byAdding: DateComponents(day: day), to: Date.startOfDay()),
                  let endOfSleep = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: endOfSleepDay) else {
                dailySleepData.append(0)
                continue
            }
            
            
            let sleepType = HKCategoryType(.sleepAnalysis)

            let dateRangePredicate = HKQuery.predicateForSamples(withStart: startOfSleep, end: endOfSleep, options: .strictEndDate)
            let allAsleepValuesPredicate = HKCategoryValueSleepAnalysis.predicateForSamples(equalTo: HKCategoryValueSleepAnalysis.allAsleepValues)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dateRangePredicate, allAsleepValuesPredicate])

            let descriptor = HKSampleQueryDescriptor(
                predicates: [.categorySample(type: sleepType, predicate: compoundPredicate)],
                sortDescriptors: []
            )
            
            let results = try await descriptor.result(for: healthStore)

            var secondsAsleep = 0.0
            for result in results {
                secondsAsleep += result.endDate.timeIntervalSince(result.startDate)
            }
            
            // Append the hours of sleep for that date
            dailySleepData.append(secondsAsleep / (60 * 60))
        }
        
        return dailySleepData
    }

    private func createLastTwoWeeksPredicate() -> NSPredicate {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: DateComponents(day: -14), to: now) ?? Date()
        return HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
    }
}

extension HealthDataFetcher {
    func fetchAndProcessHealthData() async throws -> [HealthData] {
        try await requestAuthorization()

        let calendar = Calendar.current
        let today = Date()
        var healthData: [HealthData] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yy"
        

        for day in 1...14 {
            guard let endDate = calendar.date(byAdding: .day, value: -day, to: today) else { continue }
            healthData.append(
                HealthData(
                    date: dateFormatter.date(from: DateFormatter.localizedString(from: endDate, dateStyle: .short, timeStyle: .none))!
                )
            )
        }

        healthData = healthData.reversed()

        async let stepCounts = fetchLastTwoWeeksStepCount()
        async let sleepHours = fetchLastTwoWeeksSleep()
        async let caloriesBurned = fetchLastTwoWeeksActiveEnergy()
        async let exerciseTime = fetchLastTwoWeeksExerciseTime()
        async let bodyMass = fetchLastTwoWeeksBodyWeight()
        async let daylightMinutes = fetchLastTwoWeeksTimeinDaylight()

        let fetchedStepCounts = try? await stepCounts
        let fetchedSleepHours = try? await sleepHours
        let fetchedCaloriesBurned = try? await caloriesBurned
        let fetchedExerciseTime = try? await exerciseTime
        let fetchedBodyMass = try? await bodyMass
        let fetchedDaylightMinutes = try? await daylightMinutes
        
        var screenTimeTotal: [Double] = [5.26, 5.11, 3.38,5.38,5.12,6.18,6.28,7.5,5.37,5.29,5.19,5.1,6.12,8.25]
        var screenTimeSocial: [Double] = [1.08,1.48,1.23,2.44,2.31,2.25,2.56,2.47,2.31,2.39,2.27,2.25,2.33,1.06]
        
        if let urlString = UserDefaults.standard.string(forKey: "screentimeConsumptionEndpoint"),
           let url = URL(string: urlString) {
            let semaphore = DispatchSemaphore(value: 0)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            var responseData: Data?
            var responseError: Error?
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                responseData = data
                responseError = error
                semaphore.signal()  // Signal that the task is completed
            }
            task.resume()
            semaphore.wait()
            if let error = responseError {
                print("Error fetching data: \(error.localizedDescription)")
            } else if let data = responseData {
                do {
                    let decoder = JSONDecoder()
                    let screenTimeData = try decoder.decode(ScreenTimeData.self, from: data)
                    
                    // Access the fetched data
                    screenTimeTotal = screenTimeData.screenTimeTotal
                    screenTimeSocial = screenTimeData.screenTimeSocial
                    
                    // Use the variables as needed
                    print("Total Screen Time: \(screenTimeTotal)")
                    print("Social Screen Time: \(screenTimeSocial)")
                } catch {
                    print("Error decoding JSON: \(error.localizedDescription)")
                }
            } else {
                print("No data received")
            }
        } else {
            print("URL not found in UserDefaults")
        }
        
        

        for day in 0...13 {
            healthData[day].steps = fetchedStepCounts?[day]
            healthData[day].sleepHours = fetchedSleepHours?[day]
            healthData[day].activeEnergy = fetchedCaloriesBurned?[day]
            healthData[day].exerciseMinutes = fetchedExerciseTime?[day]
            healthData[day].bodyWeight = fetchedBodyMass?[day]
            healthData[day].minutesInDaylight = fetchedDaylightMinutes?[day]
            healthData[day].screenTimeTotal = screenTimeTotal[day]
            healthData[day].screenTimeSocialMedia = screenTimeSocial[day]
        }
        

        return healthData
    }
}
