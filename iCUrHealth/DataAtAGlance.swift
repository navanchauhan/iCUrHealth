//
//  DataAtAGlance.swift
//  iCUrHealth
//
//  Created by Navan Chauhan on 2/10/24.
//

import SwiftUI
import Charts

struct Analysis: Hashable {
    var image: String?
    var prediction: String
    var category: String
    var rank: Int = 0 // Neutral = 0, Good = 1, Bad = -1
}

func getFormattedSeriesLabel(_ series: String)-> String {
    switch series {
    case "steps":
        return "Steps"
    case "activeEnergy":
        return "Active Energy"
    case "exerciseMinutes":
        return "Exercise Minutes"
    case "sleepHours":
        return "Sleep Hours"
    case "minutesInDaylight":
        return "Minutes In Daylight"
    case "bodyWeight":
        return "Body Weight"
    case "screenTimeSocialMedia":
        return "Time Spent browsing Social Media"
    case "screenTimeTotal":
        return "Total Screen Time"
    default:
        return ""
    }
}

struct CorrelationEntry: Identifiable {
    let series1: String
    let series2: String
    let pValue: Double
    let id = UUID()
    var pValueString: String {
            String(format: "%.2f", pValue)  // Format as needed
    }
    var formattedSeries1Label: String {
        return getFormattedSeriesLabel(series1)
    }
    var formattedSeries2Label: String {
        return getFormattedSeriesLabel(series2)
    }
}

func pearsonCorrelation(xs: [Double], ys: [Double]) -> Double? {
    let sumX = xs.reduce(0, +)
    let sumY = ys.reduce(0, +)
    let sumXSquared = xs.map { $0 * $0 }.reduce(0, +)
    let sumYSquared = ys.map { $0 * $0 }.reduce(0, +)
    let sumXY = zip(xs, ys).map(*).reduce(0, +)
    let n = Double(xs.count)
    
    let numerator = n * sumXY - sumX * sumY
    let denominator = sqrt((n * sumXSquared - pow(sumX, 2)) * (n * sumYSquared - pow(sumY, 2)))
    
    // Check for division by zero
    if denominator == 0 {
        return nil
    }
    
    return numerator / denominator
}

struct DataAtAGlance: View {
    @State var healthData: [HealthData] = []
    @State var predictions: [Analysis] = []
    @State var correlations: [CorrelationEntry] = []
    @AppStorage("countZeroSleepAsNoSleep") var countZeroSleepAsNoSleep: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                
                List {
                    Section(header: Text("Trend Analysis"), footer: Text("Data synced from Apple Health")) {
                        ForEach(predictions, id: \.self) { pred in
                            NavigationLink {
                                DetailedAnalysisView(healthData: self.healthData, prediction: pred)
                            }
                        label: {
                            VStack {
                                HStack {
                                    if let img = pred.image {
                                        Image(systemName: img)
                                    }
                                    Text(pred.category).font(.callout)
                                    Spacer()
                                }.padding(.bottom, 1)
                                Text(pred.prediction)
                            }
                        }
                        }
                    }
                    Section(header: Text("Correlation Analysis"), footer: Text("The Pearson correlation coefficient ranges from -1 to 1, where -1 indicates a perfect negative linear relationship, 0 indicates no linear relationship, and 1 indicates a perfect positive linear relationship between two variables.")) {
                        ForEach(correlations) { correl in
                            HStack  {
                                if correl.pValue > 0.8 {
                                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                        .foregroundStyle(.green)
                                } else if correl.pValue > 0.45 {
                                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                        .foregroundStyle(.orange)
                                } else if correl.pValue < -0.8 {
                                    Image(systemName: "chart.line.downtrend.xyaxis.circle.fill")
                                        .foregroundStyle(.red)
                                } else if correl.pValue < -0.45 {
                                    Image(systemName: "chart.line.downtrend.xyaxis.circle.fill")
                                        .foregroundStyle(.orange)
                                } else {
                                    Image(systemName: "chart.line.flattrend.xyaxis.circle.fill")
                                }
                                Text("\(correl.formattedSeries1Label) & \(correl.formattedSeries2Label) r = \(correl.pValueString)")
                                Spacer()
                            }
                        }
                    }
                }.listRowSpacing(10)
                
                
                
                Text("Data for last \(healthData.count) days")
                    .onAppear {
                        let healthDataFetcher = HealthDataFetcher()
                        self.predictions = []
                        Task {
                            self.healthData = try await healthDataFetcher.fetchAndProcessHealthData()
                            
                            let splitNum: Int = self.healthData.count / 2
                            print(splitNum)
                            
                            let initial = self.healthData.prefix(splitNum)
                            let recent = self.healthData.suffix(splitNum)
                            
                            var initial_total = 0
                            var initial_count = 0
                            
                            var final_total = 0
                            var final_count = 0
                            
                            for myValue in Array(initial) {
                                if myValue.steps != nil {
                                    initial_total += Int(myValue.steps!)
                                    initial_count += 1
                                }
                            }
                            
                            for myValue in Array(recent) {
                                if myValue.steps != nil {
                                    final_total += Int(myValue.steps!)
                                    final_count += 1
                                }
                            }
                            
                            var init_avg = max(initial_total / initial_count,1)
                            var rece_avg = final_total / final_count
                            
                            var percentage = rece_avg*100/init_avg
                            
                            var pred = Analysis(image: "figure.walk.motion", prediction: "", category: "Steps")
                            
                            if abs(percentage-100) > 5  {
                                if (percentage-100) > 0 {
                                    pred.prediction = "Your steps average in the last 7 days has been higher compared to the week before by (\(percentage-100))%"
                                } else {
                                    pred.prediction = "Your steps average in the last 7 days has been lower compared to the week before"
                                }
                            } else {
                                pred.prediction = "Your steps average in the last 7 days is relatively simimlar compared to the week before."
                            }
                            
                            self.predictions.append(pred)
                            
                            // Sleep
                            
                            initial_total = 0
                            initial_count = 0
                            
                            final_total = 0
                            final_count = 0
                            
                            for myValue in Array(initial) {
                                if myValue.sleepHours != nil && myValue.sleepHours! != 0 {
                                    initial_total += Int(myValue.sleepHours!)
                                    initial_count += 1
                                } else {
                                    if countZeroSleepAsNoSleep {
                                        initial_count += 1
                                    }
                                }
                            }
                            
                            for myValue in Array(recent) {
                                if myValue.sleepHours != nil && myValue.sleepHours! != 0 {
                                    final_total += Int(myValue.sleepHours!)
                                    final_count += 1
                                } else {
                                    if countZeroSleepAsNoSleep {
                                        final_count += 1
                                    }
                                }
                            }
                            if initial_total == 0 || final_total == 0 {
                                
                            } else
                            {
                                print("What is happening", initial_total, final_total, initial_count, final_count)
                                init_avg = initial_total / initial_count
                                rece_avg = final_total / final_count
                                
                                percentage = rece_avg*100/init_avg
                                
                                
                                pred = Analysis(image: "bed.double", prediction: "", category: "Sleep")
                                if abs(percentage-100) > 5  {
                                    if (percentage-100) > 0 {
                                        pred.prediction = "Your sleep average in the last 7 days has been higher compared to the week before by (\(percentage-100))%"
                                    } else {
                                        pred.prediction = "You have been sleeping \(init_avg - rece_avg) hours fewer compared to last week"
                                        pred.rank = -1
                                    }
                                } else {
                                    pred.prediction = "Your sleep average in the last 7 days is relatively simimlar compared to the week before."
                                }
                                
                                self.predictions.append(pred)
                            }
                            
                            // Exercise Minutes
                            
                            initial_total = 0
                            initial_count = 0
                            
                            for myValue in Array(initial) {
                                if myValue.exerciseMinutes != nil {
                                    initial_total += Int(myValue.exerciseMinutes!)
                                    initial_count += 1
                                } else {
                                    initial_count += 0
                                }
                            }
                            
                            for myValue in Array(recent) {
                                if myValue.exerciseMinutes != nil {
                                    initial_total += Int(myValue.sleepHours!)
                                    initial_count += 1
                                } else {
                                    initial_count += 0
                                }
                            }
                            
                            init_avg = initial_total / initial_count
                            
                            
                            pred = Analysis(image: "figure.play", prediction: "You have spent an average of \(init_avg) minutes exercising every day in the past two weeks", category: "Exercise Minutes")
                            
                            if init_avg < 20 {
                                pred.rank = -1
                            } else if init_avg > 60 {
                                pred.rank = 1
                            }
                            
                            self.predictions.append(pred)
                            
                            // END
                            
                            // Screen Time
                            
                            initial_total = 0
                            initial_count = 0
                            
                            final_total = 0
                            final_count = 0
                            
                            for myValue in Array(initial) {
                                if myValue.screenTimeTotal != nil {
                                    initial_total += Int(myValue.screenTimeTotal!)
                                    initial_count += 1
                                }
                            }
                            
                            for myValue in Array(recent) {
                                if myValue.screenTimeTotal != nil {
                                    final_total += Int(myValue.screenTimeTotal!)
                                    final_count += 1
                                }
                            }
                            
                            init_avg = max(initial_total / initial_count,1)
                            rece_avg = final_total / final_count
                            
                            percentage = rece_avg*100/init_avg
                            
                            pred = Analysis(image: "iphone", prediction: "", category: "Screen Time")
                            if abs(percentage-100) > 5  {
                                if (percentage-100) > 0 {
                                    pred.prediction = "Your screen time in the last 7 days has been higher compared to the week before by (\(percentage-100))%"
                                } else {
                                    pred.prediction = "You have been using your phone \(init_avg - rece_avg) hours fewer compared to last week"
                                    pred.rank = -1
                                }
                            } else {
                                pred.prediction = "Your screen time in the last 7 days is relatively similar compared to the week before."
                            }
                            
                            self.predictions.append(pred)
                            
                            // END
                            
                            let propertyNames =  ["steps", "activeEnergy", "exerciseMinutes", "sleepHours", "minutesInDaylight", "bodyWeight", "screenTimeSocialMedia", "screenTimeTotal"]
                            var correlationEntries: [CorrelationEntry] = []
                            
                            for i in 0..<propertyNames.count {
                                for j in (i+1)..<propertyNames.count {
                                    var series1KeyPath: KeyPath<HealthData, Double?> = \HealthData.steps // default initialization
                                    var series2KeyPath: KeyPath<HealthData, Double?> = \HealthData.activeEnergy // default initialization

                                    switch propertyNames[i] {
                                        case "steps":
                                            series1KeyPath = \HealthData.steps
                                        case "activeEnergy":
                                            series1KeyPath = \HealthData.activeEnergy
                                        case "exerciseMinutes":
                                            series1KeyPath = \HealthData.exerciseMinutes
                                        case "sleepHours":
                                            series1KeyPath = \HealthData.sleepHours
                                        case "minutesInDaylight":
                                            series1KeyPath = \HealthData.minutesInDaylight
                                        case "screenTimeTotal":
                                        series1KeyPath = \HealthData.screenTimeTotal
                                    case "screenTimeSocialMedia":
                                        series1KeyPath = \HealthData.screenTimeSocialMedia
                                    case "bodyWeight":
                                        series1KeyPath = \HealthData.bodyWeight
                                        default:
                                            break
                                    }

                                    switch propertyNames[j] {
                                        case "steps":
                                            series2KeyPath = \HealthData.steps
                                        case "activeEnergy":
                                            series2KeyPath = \HealthData.activeEnergy
                                        case "exerciseMinutes":
                                            series2KeyPath = \HealthData.exerciseMinutes
                                        case "sleepHours":
                                            series2KeyPath = \HealthData.sleepHours
                                        case "minutesInDaylight":
                                            series2KeyPath = \HealthData.minutesInDaylight
                                    case "bodyWeight":
                                        series2KeyPath = \HealthData.bodyWeight
                                    case "screenTimeTotal":
                                    series2KeyPath = \HealthData.screenTimeTotal
                                case "screenTimeSocialMedia":
                                    series2KeyPath = \HealthData.screenTimeSocialMedia
                                        default:
                                            break
                                    }

                                    // Now you can use series1KeyPath and series2KeyPath to access the properties dynamically
                                    let filteredData = healthData.filter { $0[keyPath: series1KeyPath] != nil && $0[keyPath: series2KeyPath] != nil }
                                    let xs = filteredData.compactMap { $0[keyPath: series1KeyPath] }
                                    let ys = filteredData.compactMap { $0[keyPath: series2KeyPath] }

                                    // Calculate Pearson correlation coefficient
                                    if let correlation = pearsonCorrelation(xs: xs, ys: ys) {
                                        let entry = CorrelationEntry(series1: propertyNames[i], series2: propertyNames[j], pValue: correlation)
                                        correlationEntries.append(entry)
                                    }
                                }
                            }

                            self.correlations = correlationEntries

                            
                        }
                    }
            }
            .navigationTitle("Analysis")
        }
    }
}

#Preview {
    DataAtAGlance()
}
