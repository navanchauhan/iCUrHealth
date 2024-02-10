//
//  UserCharts.swift
//  iCUrHealth
//
//  Created by Gregory Sinnott on 2/10/24.
//

import SwiftUI

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

struct UserCharts: View {
    var charts: [userChart]
    var body: some View {
        VStack{
            ForEach(charts) {
                chart in
                VStack{
                    HealthChart(chart: chart, average: chart.getTrend())
                }
            }
        }
        
    }
}
//
//#Preview {
//    UserCharts()
//}
