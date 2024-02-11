//
//  SettingsView.swift
//  iCUrHealth
//
//  Created by Navan Chauhan on 2/11/24.
//

import SwiftUI
import iPhoneNumberField

struct SettingsView: View {
    
    @AppStorage("nursePhone") var nursePhone: String = "+13034925101"
    @AppStorage("fullName") var fullName: String = "John Doe"
    @AppStorage("studentID") var studentID: String = "54329"
    @AppStorage("dateOfBirth") var dateOfBirth: String = "2002-01-15"
    @AppStorage("screentimeConsumptionEndpoint") var screentimeAPIEndpoint: String = "https://gist.githubusercontent.com/navanchauhan/74b3c4c7f3e9d94bf1500ce0a813bc3b/raw/f2c890366db6d2cf695a2049a50d5b91de01cb08/navan.json"
    @AppStorage("countZeroSleepAsNoSleep") var countZeroSleepAsNoSleep: Bool = false
    @AppStorage("trackSkiing") var trackSkiing: Bool = true
    @AppStorage("trackCycling") var trackCycling: Bool = true
    @AppStorage("defaultChart") var defaultChart: String = "Steps"
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Medical Details")) {
                    HStack {
                        Text("Nurse Helpine")
                        iPhoneNumberField("Nurse Phoneline", text: $nursePhone)
                    }
                    TextField("Full Name", text: $fullName)
                    TextField("Student ID", text: $studentID)
                    TextField("Date of Birth", text: $dateOfBirth)
                    
                }
                
                Section(header: Text("Dashboard Customization")) {
                    Toggle(isOn: $trackSkiing) {
                        Text("Track Skiing Workouts")
                    }
                    Toggle(isOn: $trackCycling) {
                        Text("Track Mountain Biking Workouts")
                    }
                    Picker("Default Chart", selection: $defaultChart) {
                        Text("Steps").tag("Steps")
                        Text("Calories Burned").tag("Calories Burned")
                        Text("Exercise Minutes").tag("Exercise Minutes")
                    }
                }
                
                Section(header: Text("Advance Settings")) {
                    TextField("ScreenTime Consumption Endpoint", text: $screentimeAPIEndpoint)
                    Toggle(isOn: $countZeroSleepAsNoSleep) {
                        Text("Count 0 hours of sleep as no sleep")
                    }
                }
            }
        }
    }
}
