//
//  AutoCallerSheet.swift
//  iCUrHealth
//
//  Created by Navan Chauhan on 2/11/24.
//

import SwiftUI

struct Student: Codable {
    let phoneNumber: String
    let name: String
    let studentID: String
    let dateOfBirth: String
    let request: String
}

func submitStudentInfo(student: Student) {
    guard let url = URL(string: "http://127.0.0.1:8000/submit/") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
        let jsonData = try JSONEncoder().encode(student)
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "No error description.")")
                return
            }

            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("StatusCode should be 200, but is \(httpStatus.statusCode)")
                print("Response = \(response!)")
            }

            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString!)")
        }
        task.resume()
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

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
