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

func getAverage(healthData: [HealthData], valueForKey: (HealthData) -> Double?) -> Double {
    var total = 0.0
    var count = 0.0

    for data in healthData {
        if let value = valueForKey(data) {
            if value != 0.0 {
                total += value
                count += 1
            }
        }
    }

    return count > 0 ? total / count : 0
}

struct UserCharts: View {
//    var charts: [userChart]
    @State var charts: [userChart] = []
    @State var healthData: [HealthData] = []
    var body: some View {
        NavigationStack {
            List{
                VStack {
                    Text("Step Count").font(.title)
                    Chart {
                        let averageSteps = getAverage(healthData: healthData) { healthData in
                            if let steps = healthData.steps {
                                return Double(steps)
                            } else {
                                return nil // Explicitly return nil if there's no value
                            }
                        }
                        ForEach(self.healthData) { data in
                            if let stepCount = data.steps {
                                BarMark(x: .value("Date", data.date), y: .value("Steps", stepCount))
                                RuleMark(y: .value("Average", averageSteps))
                                    .foregroundStyle(Color.secondary)
                                    .lineStyle(StrokeStyle(lineWidth: 0.8, dash: [10]))
                                    .annotation(alignment: .bottomTrailing) {
                                        Text(String(format: "Your average is: %.0f", averageSteps))
                                            .font(.subheadline).bold()
                                            .padding(.trailing, 32)
                                            .foregroundStyle(Color.secondary)
                                    }
                            }
                        }
                    }.frame(height: 150)
                }
                VStack {
                    Text("Active Energy").font(.title)
                    Chart {
                        let averageEnergy = getAverage(healthData: healthData) { healthData in
                            if let val = healthData.activeEnergy {
                                return Double(val)
                            } else {
                                return nil // Explicitly return nil if there's no value
                            }
                        }
                        ForEach(self.healthData) { data in
                            if let activeEnergy = data.activeEnergy {
                                BarMark(x: .value("Date", data.date), y: .value("Active Energy", activeEnergy))
                                RuleMark(y: .value("Average", averageEnergy))
                                    .foregroundStyle(Color.secondary)
                                    .lineStyle(StrokeStyle(lineWidth: 0.8, dash: [10]))
                                    .annotation(alignment: .bottomTrailing) {
                                        Text(String(format: "Your average is: %.0f", averageEnergy))
                                            .font(.subheadline).bold()
                                            .padding(.trailing, 32)
                                            .foregroundStyle(Color.secondary)
                                    }
                            }
                        }
                    }.frame(height: 250)
                }
                VStack {
                    Text("Sleep").font(.title)
                    Chart {
                        let average = getAverage(healthData: healthData) { healthData in
                            if let val = healthData.sleepHours {
                                return Double(val)
                            } else {
                                return nil // Explicitly return nil if there's no value
                            }
                        }
                        ForEach(self.healthData) { data in
                            if let val = data.sleepHours {
                                BarMark(x: .value("Date", data.date), y: .value("Sleep", val))
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
                    }.frame(height: 250)
                }
                VStack {
                    Text("Time in Daylight").font(.title)
                    Chart {
                        let average = getAverage(healthData: healthData) { healthData in
                            if let val = healthData.minutesInDaylight {
                                return Double(val)
                            } else {
                                return nil // Explicitly return nil if there's no value
                            }
                        }
                        ForEach(self.healthData) { data in
                            if let val = data.minutesInDaylight {
                                BarMark(x: .value("Date", data.date), y: .value("Time in Daylight (minutes)", val))
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
                    }.frame(height: 250)
                }
            }.onAppear {
                let healthDataFetcher = HealthDataFetcher()
                Task {
                    self.healthData = try await healthDataFetcher.fetchAndProcessHealthData()
                }
            }.listRowSpacing(10)
                .navigationTitle("Charts")
        }
        
    }
}
//
//#Preview {
//    UserCharts()
//}
