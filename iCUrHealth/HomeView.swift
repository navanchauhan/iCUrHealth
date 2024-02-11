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
    @State private var showingSettingsSheet: Bool = false
    @State private var showingSomethingIsWrongSheet: Bool = false
    @AppStorage("nursePhone") var nursePhone: String = "+13034925101"
    @State private var hasBikingWorkouts: Bool = false
    
    @AppStorage("trackSkiing") var trackSkiing: Bool = true
    @AppStorage("trackCycling") var trackCycling: Bool = true
    @AppStorage("defaultChart") var defaultChart: String = "Steps"
    
    @StateObject private var viewModel = WorkoutViewModel()
    
    let healthStore = HKHealthStore()
    
    @State private var data: [chartData] = []
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    let telephone = "tel://"
                    guard let url = URL(string: telephone + nursePhone) else {
                        return
                    }
                    UIApplication.shared.open(url)
                }, label: {
                    Label("Call Nurse Helpline", systemImage: "cross.case.circle")
                })
                        

                            Button(action: {
                                showingSomethingIsWrongSheet = true
                            }, label: {
                                Label("Auto-Book an Appointment", systemImage: "phone.connection")
                            }).sheet(isPresented: $showingSomethingIsWrongSheet) {
                                AutoCallerSheet()
                            }
                Button(action: {
                    print("Request")
                }, label: {
                    Label("Request a call back", systemImage: "phone.arrow.down.left.fill")
                })
                
                VStack {
                    Text(defaultChart)
                    Chart(data) {
                        BarMark(x: .value("Date", $0.dateInterval),
                                y: .value("Count", $0.data)
                        )
                        
                    }
                }.frame(maxHeight: 100)
                
                if (trackSkiing) {
                    
                    if !viewModel.workoutRouteCoordinates.isEmpty {
                        VStack {
                            HStack {
                                VStack {
                                    Text("Latest Downhill Skiing Workout On \(viewModel.workout!.startDate)")
                                }
                                Spacer()
                            }
                            MapView(route: viewModel.workoutRoute!)
                                .frame(height: 300)
                            HStack {
                                VStack {
                                    Text("Total Duration")
                                    Text("\((viewModel.workout!.duration*100/3600).rounded()/100, specifier: "%.2f") hr")
                                }
                                VStack {
                                    Text("Total Distance")
                                    Text("\(viewModel.workout!.totalDistance!)")
                                }
                            }
                        }
                    } else {
                        Text("Fetching workout route...")
                            .onAppear {
                                if HKHealthStore.isHealthDataAvailable() {
                                    trigger.toggle()
                                    Task {
                                        try await fetchStepCountData()
                                    }
                                }
                                viewModel.fetchAndProcessWorkoutRoute()
                            }
                            .healthDataAccessRequest(store: healthStore,
                                                     readTypes: allTypes,
                                                     trigger: trigger) { result in
                                switch result {
                                    
                                case .success(_):
                                    authenticated = true
                                    
                                case .failure(let error):
                                    // Handle the error here.
                                    fatalError("*** An error occurred while requesting authentication: \(error) ***")
                                }
                            }
                    }
                }
                
                if (trackCycling) {
                    if (hasBikingWorkouts) {
                        
                    } else {
                        VStack {
                            Text("You have not completed any mountain biking workouts recently. Is everything alright?")
                        }
                    }
                }
                
            }.listRowSpacing(10)
                .navigationTitle("iCUrHealth")
                .toolbar {
                    Button(action: {
                        showingSettingsSheet = true
                    }, label: {
                        Label("Settings", systemImage: "gear").labelStyle(.iconOnly)
                    })
                }
        }.sheet(isPresented: $showingSettingsSheet,  onDismiss: {
            Task {
                try await fetchStepCountData()
            }
        }, content: {
            SettingsView()
        })
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
    
    func checkForCyclingWorkouts(completion: @escaping ([HKWorkout]?) -> Void) {
            let cyclingPredicate = HKQuery.predicateForWorkouts(with: .cycling)
            
            // Create a predicate to select workouts in the last 5 days
            let calendar = Calendar.current
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -5, to: endDate) else { return completion(nil) }
            let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            
            // Combine the predicates
            let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [cyclingPredicate, datePredicate])
            
            // Create the query
        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: compound, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                DispatchQueue.main.async {
                    guard let workouts = samples as? [HKWorkout], error == nil else {
                        completion(nil)
                        return
                    }
                    hasBikingWorkouts = false
                    completion(workouts)
                }
            }
            
            healthStore.execute(query)
        }
    
    private func fetchStepCountData() async throws {
        checkForCyclingWorkouts() { workouts in
        }
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())


        guard let endDate = calendar.date(byAdding: .day, value: 1, to: today) else {
            fatalError("*** Unable to calculate the end time ***")
        }


        guard let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) else {
            fatalError("*** Unable to calculate the start time ***")
        }


        let thisWeek = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        var stepType = HKQuantityType(.stepCount)
        var quantityUnit = HKUnit.count()
        // Create the query descriptor.
        switch (defaultChart) {
        case "Steps":
            stepType = HKQuantityType(.stepCount)
            quantityUnit = HKUnit.count()
        case "Calories Burned":
            stepType = HKQuantityType(.activeEnergyBurned)
            quantityUnit = HKUnit.largeCalorie()
        case "Exercise Minutes":
            stepType = HKQuantityType(.appleExerciseTime)
            quantityUnit = HKUnit.minute()
        default:
            return
        }

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
                    chartData(tag: "activity", dateInterval: stats.startDate, data: quantity.doubleValue(for: quantityUnit))
                )
            } else {
            }
            
        }
        
        data = dailyData
    }
}
