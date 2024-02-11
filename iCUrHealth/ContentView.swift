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
import MapKit

struct chartData: Identifiable {
    let tag: String
    let dateInterval: Date
    let data: Double
    var id: TimeInterval { dateInterval.timeIntervalSince1970 }
}

let allTypes: Set = [
    HKQuantityType.workoutType(),
    HKSeriesType.workoutRoute(),
    HKQuantityType(.activeEnergyBurned),
    HKQuantityType(.distanceCycling),
    HKQuantityType(.distanceWalkingRunning),
    HKQuantityType(.stepCount),
    HKQuantityType(.heartRate),
    HKCategoryType(.sleepChanges),
    HKCategoryType(.sleepAnalysis)
]

import HealthKit
import CoreLocation

struct WorkoutRoute {
    var coordinates: [CLLocationCoordinate2D]
}

class WorkoutViewModel: ObservableObject {
    @Published var workout: HKWorkout?
    @Published var workoutRoute: WorkoutRoute? {
        didSet {
            workoutRouteCoordinates = workoutRoute?.coordinates ?? []
        }
    }
    @Published var workoutRouteCoordinates: [CLLocationCoordinate2D] = []
    private var healthStore = HKHealthStore()

    func fetchAndProcessWorkoutRoute() {
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .downhillSkiing)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                // Handle the error here.
                return
            }
            
            // Process the fetched workouts here.
            for workout in workouts {
                let routePredicate = HKQuery.predicateForObjects(from: workout)
                let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: routePredicate, anchor: nil, limit: HKObjectQueryNoLimit) { (query, routeSamples, deletedObjects, anchor, error) in
                    guard let routeSamples = routeSamples as? [HKWorkoutRoute], error == nil else {
                        // Handle the error here
                        return
                    }

                    for routeSample in routeSamples {
                        let workoutRouteQuery = HKWorkoutRouteQuery(route: routeSample) { (query, locationsOrNil, done, errorOrNil) in
                            guard let locations = locationsOrNil, errorOrNil == nil else {
                                // Handle error
                                return
                            }

                            let allCoordinates = locations.map { $0.coordinate }

                            // Once all coordinates are fetched, update the published property
                            DispatchQueue.main.async {
                                self.workoutRoute = WorkoutRoute(coordinates: allCoordinates)
                                self.workout = workout
                            }

                            if done {
                                // Finish processing as needed
                            }
                        }
                        self.healthStore.execute(workoutRouteQuery)
                    }
                }
                self.healthStore.execute(routeQuery)
            }
        }

        self.healthStore.execute(workoutQuery)
    }
}

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct MapView: View {
    var route: WorkoutRoute

    // Convert coordinates to identifiable coordinates
    var identifiableCoordinates: [IdentifiableCoordinate] {
        route.coordinates.map { IdentifiableCoordinate(coordinate: $0) }
    }

    var body: some View {
        Map(coordinateRegion: .constant(regionForRoute()),
            showsUserLocation: false,
            userTrackingMode: .none,
            annotationItems: identifiableCoordinates) { item in
                MapPin(coordinate: item.coordinate, tint: .blue)
            }
            .overlay(
                MapOverlay(coordinates: route.coordinates)
                    .stroke(Color.blue, lineWidth: 3)
            )
            .cornerRadius(10) // Optional: Adds rounded corners to the map
    }

    func regionForRoute() -> MKCoordinateRegion {
//        guard let firstCoordinate = route.coordinates.first else {
//            return MKCoordinateRegion()
//        }
        
        let count = route.coordinates.count / 2
        guard let firstCoordinate = route.coordinates.prefix(count).last else {
            return MKCoordinateRegion()
        }
        
        return MKCoordinateRegion(center: firstCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    }
}

struct MapOverlay: Shape {
    var coordinates: [CLLocationCoordinate2D]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard let firstCoordinate = coordinates.first else {
            return path
        }

        let mapRect = MKMapRect.world
        let firstPoint = MKMapPoint(firstCoordinate)
        let startPoint = CGPoint(x: (firstPoint.x / mapRect.size.width) * rect.size.width, y: (1 - firstPoint.y / mapRect.size.height) * rect.size.height)
        path.move(to: startPoint)

        for coordinate in coordinates.dropFirst() {
            let mapPoint = MKMapPoint(coordinate)
            let point = CGPoint(x: (mapPoint.x / mapRect.size.width) * rect.size.width, y: (1 - mapPoint.y / mapRect.size.height) * rect.size.height)
            path.addLine(to: point)
        }

        return path
    }
}


struct ContentView: View {
    @State var authenticated = false
    @State var trigger = false
    
    @StateObject private var viewModel = WorkoutViewModel()
    
    let healthStore = HKHealthStore()
    
    @State private var data: [chartData] = []
    
    var body: some View {
            TabView{
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
                            .navigationTitle("iCUrHealth")
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
                }
                .padding()
                .navigationTitle("iCUrHealth")
                
                .tabItem {
                    Image(systemName: "gear")
                    Text("Home")
                }
                UserCharts()
                    .tabItem {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Charts")
                    }
                DataAtAGlance()
                    .tabItem {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Trends")
                    }
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

#Preview {
    ContentView()
}
