import SwiftUI

struct ChartDetailView: View {
    @StateObject private var vm: ChartViewModel
    
    init(ticker: String, apiKey: String) {
        _vm = StateObject(wrappedValue: ChartViewModel(ticker: ticker, apiKey: apiKey))
    }
    
    var body: some View {
        VStack {
            // Price and Changes Header
            if let previousClose = vm.previousClose {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$\(previousClose.c, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let change = vm.priceChange, let percentChange = vm.percentChange {
                        HStack {
                            Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f")")
                                .foregroundColor(change >= 0 ? .green : .red)
                            Text("(\(percentChange >= 0 ? "+" : "")\(percentChange, specifier: "%.2f")%)")
                                .foregroundColor(percentChange >= 0 ? .green : .red)
                        }
                        .font(.subheadline)
                    } else {
                        Text("Change data unavailable")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Chart or Loading State
            if let chartData = vm.chart {
                ChartView(data: chartData, vm: vm)
            } else if vm.fetchPhase == .fetching {
                ProgressView("Loading \(vm.ticker)...")
            } else {
                Text("No data available for \(vm.ticker)")
            }
            
            // Range Picker and Buttons
            HStack {
                Picker("Time Range", selection: $vm.selectedRange) {
                    ForEach(ChartRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                
                Spacer() // Pushes buttons to the far right
                
                HStack(spacing: 10) {
                    Button("Buy") {
                        print("Buy action for \(vm.ticker)")
                        // Add buy logic here
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Sell") {
                        print("Sell action for \(vm.ticker)")
                        // Add sell logic here
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red) // Warning color (red)
                }
            }
            .padding()
        }
        .navigationTitle(vm.ticker)
        .task { await vm.fetchData() }
    }
}

#Preview {
    ChartDetailView(ticker: "AAPL", apiKey: "API_KEY")
}
