//
//  ContentView.swift
//  iCUrHealth
//
//  Created by Navan Chauhan on 2/9/24.
//

import SwiftUI
import HealthKit
import HealthKitUI

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

func stepCount(healthStore: HKHealthStore) async throws {
    let stepType = HKQuantityType(.stepCount)
    let descriptor = HKSampleQueryDescriptor(predicates:[.quantitySample(type: stepType)], sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)], limit: 10)
    let descriptor = HKSampleQuery(
    
    let results = try await descriptor.result(for: healthStore)
    
    for result in results {
        print(result)
    }
}

struct ContentView: View {
    @State var authenticated = false
    @State var trigger = false
    
    let healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Button(action: {
                trigger.toggle()
            }) {
                Text("Force Permissions")
            }
            Button(action: {
                if HKHealthStore.isHealthDataAvailable() {
                    print("YES!")
                    Task {
                        try await stepCount(healthStore: healthStore)
                    }
                    
                    
                } else {
                    print("NOOOO!")
                }
            }) {
                Text("Test Healthkit stuff")
            }.disabled(!authenticated)
            
                .onAppear() {
                            
                            // Check that Health data is available on the device.
                            if HKHealthStore.isHealthDataAvailable() {
                                // Modifying the trigger initiates the health data
                                // access request.
                                trigger.toggle()
                            }
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
        .padding()
    }
}

#Preview {
    ContentView()
}
