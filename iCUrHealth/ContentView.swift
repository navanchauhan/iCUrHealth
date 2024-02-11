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

struct ContentView: View {
    @State var authenticated = false
    @State var trigger = false
    
    @StateObject private var viewModel = WorkoutViewModel()
    
    let healthStore = HKHealthStore()
    
    @State private var data: [chartData] = []
    
    var body: some View {
            TabView{
                HomeView()
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
}
