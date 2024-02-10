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

struct DataAtAGlance: View {
    @State var healthData: [HealthData] = []
    @State var predictions: [Analysis] = []
    
    var body: some View {
        NavigationView {
            VStack {
                
                List(predictions, id: \.self) { pred in
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
                            
                            var init_avg = initial_total / initial_count
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
                                if myValue.sleepHours != nil {
                                    initial_total += Int(myValue.sleepHours!)
                                    initial_count += 1
                                }
                            }
                            
                            for myValue in Array(recent) {
                                if myValue.sleepHours != nil {
                                    final_total += Int(myValue.sleepHours!)
                                    final_count += 1
                                }
                            }
                            
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
                            
                            // Exercise Minutes
                            
                            initial_total = 0
                            initial_count = 0
                            
                            for myValue in Array(initial) {
                                if myValue.exerciseMinutes != nil {
                                    initial_total += Int(myValue.exerciseMinutes!)
                                    initial_count += 1
                                } else {
                                    initial_count += 1
                                }
                            }
                            
                            for myValue in Array(recent) {
                                if myValue.exerciseMinutes != nil {
                                    initial_total += Int(myValue.sleepHours!)
                                    initial_count += 1
                                } else {
                                    initial_count += 1
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
                        }
                    }
            }
            .navigationTitle("Trend Analysis")
        }
    }
}

#Preview {
    DataAtAGlance()
}
