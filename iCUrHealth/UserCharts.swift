//
//  UserCharts.swift
//  iCUrHealth
//
//  Created by Gregory Sinnott on 2/10/24.
//

import SwiftUI

struct userChart: Identifiable {
    let type: String
    let data1: [chartData]
    var id = UUID()
    func getTrend() -> Double{
        var trend: Double
        var values: [Double] = []
        for dataPoint in data1 {
            values.append(dataPoint.data)
        }
        trend = values.reduce(0.0, +)
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
                    let trend = chart.getTrend()
                    let trendString = String(trend)
                    Text(trendString)
                    HealthChart(chart: chart)
                }
            }
        }
        
    }
}
//
//#Preview {
//    UserCharts()
//}
