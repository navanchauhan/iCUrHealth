//
//  AutoCallerSheet.swift
//  iCUrHealth
//
//  Created by Navan Chauhan on 2/11/24.
//

import SwiftUI

struct AutoCallerSheet: View {
    
    @State private var helpNeeded: String
    
    init(helpNeeded: String = "") {
        self.helpNeeded = helpNeeded
    }
    
    var body: some View {
        Form {
            Section {
                Text("Looks like something is wrong. Tell me a bit about your symptoms and I can go ahead and make the right appointment for you...")
                TextField("Describe...", text: $helpNeeded, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                Button("Make Appointment") {
                    print("Making an appointment")
                }
            }
        }
    }
}

#Preview {
    AutoCallerSheet()
}
