//
//  WorkoutMapView.swift
//  iCUrHealth
//
//  Created by Navan Chauhan on 2/10/24.
//

import SwiftUI
import HealthKit
import CoreLocation
import MapKit

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
