//
//  ChartDetailView.swift
//  Final Project
//
//  Created by Emmanuel Makoye on 4/6/25.
//


//
//  ChartDetailView.swift
//  PlayGround
//
//  Created by Emmanuel Makoye on 4/6/25.
//


import SwiftUI

struct ChartDetailView: View {
    @StateObject private var vm: ChartViewModel
    private var ticker: String
    
    init(ticker: String, apiKey: String) {
        _vm = StateObject(wrappedValue: ChartViewModel(ticker: ticker, apiKey: apiKey))
        self.ticker = ticker
    }
    
    var body: some View {
        VStack {
            if let chartData = vm.chart {
                ChartView(data: chartData, vm: vm)
            } else if vm.fetchPhase == .fetching {
                ProgressView("Loading \(vm.ticker)...")
            } else {
                Text("No data available for \(vm.ticker)")
            }
            
            Picker("Time Range", selection: $vm.selectedRange) {
                ForEach(ChartRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding()
        }
        .navigationTitle(vm.ticker)
        .task { await vm.fetchData() }
    }
}

#Preview {
    ChartDetailView(ticker: "AAPL", apiKey: "lonqIUMp0Bztqiqqa_yeTLDZQVs3frHG")
}
