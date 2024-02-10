//
//  ContentView.swift
//  iCUrHealth
//
//  Created by Navan Chauhan on 2/9/24.
//

import SwiftUI
import HealthKit
import HealthKitUI
import Charts

struct chartData: Identifiable {
    
    let dateInterval: Date
    let data: Double
    var id: TimeInterval { dateInterval.timeIntervalSince1970 }
}

let allTypes: Set = [
    HKQuantityType.workoutType(),
    HKQuantityType(.activeEnergyBurned),
    HKQuantityType(.distanceCycling),
    HKQuantityType(.distanceWalkingRunning),
    HKQuantityType(.stepCount),
    HKQuantityType(.heartRate),
    HKCategoryType(.sleepChanges),
    HKCategoryType(.sleepAnalysis)
]

struct ContentView: View {
    @State var authenticated = false
    @State var trigger = false
    
    let healthStore = HKHealthStore()
    
    @State private var data: [chartData] = []
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Steps")
                    Chart(data) {
                        BarMark(x: .value("Date", $0.dateInterval),
                                y: .value("Count", $0.data)
                        )
                        
                    }
                }.frame(maxHeight: 100)
                Button(action: {
                    Task {
                        try await fetchStepCountData()
                    }
                })
                     {
                    Text("Exp Function")
                }
                Spacer()
                .onAppear() {
                    if HKHealthStore.isHealthDataAvailable() {
                        trigger.toggle()
                    }
                }
                .healthDataAccessRequest(store: healthStore,
                                         readTypes: allTypes,
                                         trigger: trigger) { result in
                    switch result {
                        
                    case .success(_):
                        authenticated = true
                        Task {
                            try await fetchStepCountData()
                        }
                    case .failure(let error):
                        // Handle the error here.
                        fatalError("*** An error occurred while requesting authentication: \(error) ***")
                    }
                }
            }
            .padding()
            .navigationTitle("iCUrHealth")
        }
    }
    
    private func fetchStepCountData() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())


        guard let endDate = calendar.date(byAdding: .day, value: 1, to: today) else {
            fatalError("*** Unable to calculate the end time ***")
        }


        guard let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) else {
            fatalError("*** Unable to calculate the start time ***")
        }


        let thisWeek = HKQuery.predicateForSamples(withStart: startDate, end: endDate)


        // Create the query descriptor.
        let stepType = HKQuantityType(.stepCount)
        let stepsThisWeek = HKSamplePredicate.quantitySample(type: stepType, predicate:thisWeek)
        let everyDay = DateComponents(day:1)


        let sumOfStepsQuery = HKStatisticsCollectionQueryDescriptor(
            predicate: stepsThisWeek,
            options: .cumulativeSum,
            anchorDate: endDate,
            intervalComponents: everyDay)


        let stepCounts = try await sumOfStepsQuery.result(for: self.healthStore)
        
        var dailyData: [chartData] = []
        
        stepCounts.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
            if let quantity = stats.sumQuantity() {
                //print(quantity, stats.startDate)
                dailyData.append(
                    chartData(dateInterval: stats.startDate, data: quantity.doubleValue(for: HKUnit.count()))
                )
            } else {
            }
            
        }
        
        data = dailyData
    }
}

#Preview {
    ContentView()
}
