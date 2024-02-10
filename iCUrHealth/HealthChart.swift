//
//  HealthChart.swift
//  iCUrHealth
//
//  Created by Gregory Sinnott on 2/10/24.
//

import SwiftUI
import Charts

func generateTrendData(chart: [chartData], average: Double) -> [chartData]{
    var trendData: [chartData] = []
    for chartPoint in chart {
        trendData.append(chartData(tag: "trend", dateInterval: chartPoint.dateInterval, data: average))
    }
    return trendData
}

func combineTrend(chart: [chartData], trend: [chartData]) -> [chartData]{
    return(chart+trend)
}

struct HealthChart: View {
    var chart: userChart
    var average: Double
    var body: some View {
        VStack{
            Text("Your Charts").font(.title)
            switch chart.type{
            case "bar":
                ScrollView{
                    VStack(alignment: .leading){
                        VStack(alignment: .leading) {
                            Text(chart.metric)
                                .font(.title3).bold()
                            Text("Last 30 days")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.bottom)
                        }
                        Chart(chart.data) {
                            BarMark(x: .value("Date", $0.dateInterval),
                                    y: .value("Count", $0.data)
                            )
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
                }
                .frame(height: 300)
                .padding()
                
            case "line":
                Chart(chart.data) {
                    LineMark(x: .value("Date", $0.dateInterval),
                             y: .value("Count", $0.data)
                    )
                    RuleMark(y: .value("Average", average))
                        .foregroundStyle(Color.secondary)
                }
            case "trend":
                Chart(generateTrendData(chart: chart.data, average: average)) {
                    LineMark(x: .value("Date", $0.dateInterval),
                             y: .value("Count", $0.data)
                    )
                }
            default:
                Text("No chart found")
            }
        }
        
    }
}


//#Preview {
//    HealthChart()
//}
