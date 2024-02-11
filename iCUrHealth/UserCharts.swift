//
//  UserCharts.swift
//  iCUrHealth
//
//  Created by Gregory Sinnott on 2/10/24.
//

import SwiftUI
import Charts

struct userChart: Identifiable {
    let type: String
    let metric: String
    let data: [chartData]
    var id = UUID()
    func getTrend() -> Double{
        var trend: Double
        var values: [Double] = []
        for dataPoint in data {
            values.append(dataPoint.data)
        }
        let sum = values.reduce(0.0, +)
        trend = sum / Double(values.count)
        return trend
    }
    
}

func getAverage(healthData: [HealthData]) -> Double {
    var total = 0.0
    var count = 0.0
    for data in healthData {
            if let stepCount = data.steps {
                total += Double(stepCount) // Assuming stepCount is an Int
                count += 1
            }
        }
    if count > 0 {
            return total / count
        } else {
            return 0 // Return 0 to avoid division by zero if there are no step counts
        }
}

struct UserCharts: View {
//    var charts: [userChart]
    @State var charts: [userChart] = []
    @State var healthData: [HealthData] = []
    var body: some View {
        VStack{
            Text("Step Count").font(.title)
            Chart {
                let average = getAverage(healthData: self.healthData)
                ForEach(self.healthData) { data in
                    if let stepCount = data.steps {
                        BarMark(x: .value("Date", data.date), y: .value("Steps", stepCount))
                        RuleMark(y: .value("Average", average))
                            .foregroundStyle(Color.secondary)
                            .lineStyle(StrokeStyle(lineWidth: 0.8, dash: [10]))
                            .annotation(alignment: .bottomTrailing) {
                                Text(String(format: "Your average is: %.0f", average))
                                    .font(.subheadline).bold()
                                    .padding(.trailing, 32)
                                    .foregroundStyle(Color.secondary)
                            }
                    }
                }
            }.frame(height: 150)
            Text("Active Energy").font(.title)
            Chart {
                ForEach(self.healthData) { data in
                    if let activeEnergy = data.activeEnergy {
                        BarMark(x: .value("Date", data.date), y: .value("Active Energy", activeEnergy))
                        RuleMark(y: .value("Average", 10.0))
                            .foregroundStyle(Color.secondary)
                            .lineStyle(StrokeStyle(lineWidth: 0.8, dash: [10]))
                            .annotation(alignment: .bottomTrailing) {
                                Text(String(format: "Your average is: %.0f", 10.0))
                                    .font(.subheadline).bold()
                                    .padding(.trailing, 32)
                                    .foregroundStyle(Color.secondary)
                            }
                    }
                }
            }.frame(height: 250)
        }.onAppear {
            let healthDataFetcher = HealthDataFetcher()
            Task {
                self.healthData = try await healthDataFetcher.fetchAndProcessHealthData()
            }
        }
        
    }
}
//
//#Preview {
//    UserCharts()
//}
