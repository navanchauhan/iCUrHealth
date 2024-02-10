//
//  HealthChart.swift
//  iCUrHealth
//
//  Created by Gregory Sinnott on 2/10/24.
//

import SwiftUI
import Charts

struct HealthChart: View {
    var chart: userChart
    var body: some View {
        switch chart.type{
        case "bar":
            Chart(chart.data1) {
                BarMark(x: .value("Date", $0.dateInterval),
                        y: .value("Count", $0.data)
                )
        }
        case "line":
            Chart(chart.data1) {
                LineMark(x: .value("Date", $0.dateInterval),
                        y: .value("Count", $0.data)
                )
        }
        default:
            Text("No chart found")
        }
        
    }
}

//#Preview {
//    HealthChart()
//}
