//
//  HomeView.swift
//  iCUrHealth
//
//  Created by Navan Chauhan on 2/10/24.
//

import SwiftUI
import HealthKit
import HealthKitUI
import Charts

struct HomeView: View {
    @State var authenticated = false
    @State var trigger = false
    
    @StateObject private var viewModel = WorkoutViewModel()
    
    let healthStore = HKHealthStore()
    
    @State private var data: [chartData] = []
    var body: some View {
        NavigationView {
            List {
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
                if !viewModel.workoutRouteCoordinates.isEmpty {
                    VStack {
                        HStack {
                            Text("Latest Downhill Skiing Workout").font(.callout)
                            Spacer()
                        }
                        MapView(route: viewModel.workoutRoute!)
                            .frame(height: 300)
                        HStack {
                            VStack {
                                Text("Top Speed")
                                Text("\(viewModel.workout!.totalDistance!)")
                            }
                        }
                    }
                } else {
                    Text("Fetching workout route...")
                        .onAppear {
                            if HKHealthStore.isHealthDataAvailable() {
                                trigger.toggle()
                            }
                            viewModel.fetchAndProcessWorkoutRoute()
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
                
            }.listRowSpacing(10)
                .navigationTitle("iCUrHealth")
        }
    }
    
    private func experimentWithSkiWorkout() async throws {
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .downhillSkiing)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: 3, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            
            guard let workouts = samples as? [HKWorkout], error == nil else {
                // Handle the error here.
                return
            }
            
            // Process the fetched workouts here.
            for workout in workouts {
                print(workout)
            }
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
                    chartData(tag: "activity", dateInterval: stats.startDate, data: quantity.doubleValue(for: HKUnit.count()))
                )
            } else {
            }
            
        }
        
        data = dailyData
    }
}
