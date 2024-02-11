//
//  DetailedAnalysisView.swift
//  iCUrHealth
//
//  Created by Navan Chauhan on 2/10/24.
//

import SwiftUI
import Charts
import Foundation

struct DetailedAnalysisView: View {
    @State var healthData: [HealthData]
    @State var llmInput: String = ""
    let prediction: Analysis
    
    let dateFormatter = DateFormatter()
    
    
    var body: some View {
        NavigationView {
            List {
                Text(prediction.prediction)
                
                Chart {
                    ForEach(self.healthData) { data in
                        if prediction.category == "Steps" {
                            if let stepCount = data.steps {
                                BarMark(x: .value("Date", data.date), y: .value("Steps", stepCount))
                            }
                        } else if prediction.category == "Sleep" {
                            if let sleepHours = data.sleepHours {
                                BarMark(x: .value("Date", data.date), y: .value("Sleep Hours", sleepHours))
                            }
                        } else if prediction.category == "Exercise Minutes" {
                            if let exerMinutes = data.exerciseMinutes {
                                BarMark(x: .value("Date", data.date), y: .value("Exercise Minutes", exerMinutes))
                            }
                        }
                    }
                }.frame(height: 250)
                
                if prediction.category == "Sleep" {
                    Text("Sleep is crucial for various aspects of health and well-being. It allows the body and mind to recharge, enabling better cognitive function, such as improved concentration and memory retention. Adequate sleep also plays a vital role in physical health, as it is involved in the repair of the heart and blood vessels, and it supports growth and stress regulation. Furthermore, it helps regulate mood and is associated with lower risk of chronic health issues, contributing to overall quality of life.")
                } else if prediction.category == "Steps" {
                    Text("Taking regular steps, such as walking, is fundamental for maintaining physical health. It enhances cardiovascular fitness, aiding in the reduction of heart disease risk, and supports the management of body weight by burning calories. Engaging in regular walking can also strengthen bones and muscles, reducing the risk of osteoporosis and muscle loss. Additionally, it can improve mental health by reducing stress, anxiety, and depressive symptoms, contributing to an overall sense of well-being.")
                } else if prediction.category == "Exercise Minutes" {
                    Text("Regular exercise, even in short durations, is highly beneficial for health. Just a few minutes of physical activity each day can boost cardiovascular health, improving heart function and reducing the risk of heart disease. These exercise minutes can also aid in weight management by increasing metabolic rate and burning extra calories. Furthermore, engaging in daily physical activity, even briefly, can enhance mental health by releasing endorphins that reduce stress and improve mood.")
                }
                
                if prediction.rank == -1 {
                    if prediction.category == "Sleep" {
                        Text("It looks like you have not been sleeping well this week. Has something changed?")
                        TextField("Response", text: $llmInput)
                    }
                }
                
            }.listRowSpacing(10)
        }.navigationTitle(prediction.category)
    }
}
