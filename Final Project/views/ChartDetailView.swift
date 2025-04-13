import SwiftUI
import SwiftData

struct ChartDetailView: View {
    @StateObject private var vm: ChartViewModel
    @State private var showAlert: Bool = false
    @State private var selectedQuantity: Int = 1
    @Environment(\.modelContext) private var modelContext
    @Query private var portfolio: [StockItem] // All currently held stocks
    
    init(ticker: String, apiKey: String) {
        _vm = StateObject(wrappedValue: ChartViewModel(ticker: ticker, apiKey: apiKey))
    }
    
    private func getUserStock() -> StockItem? {
        return portfolio.filter { $0.ticker == vm.ticker } .first
    }
    
    private func buyStock() {
        if let stockItem = getUserStock() {
            stockItem.quantity += selectedQuantity
            try? modelContext.save()
        } else {
            modelContext.insert(StockItem(ticker: vm.ticker, quantity: selectedQuantity))
        }
    }
    
    private func sellStock() {
        if let stockItem = getUserStock() {
            stockItem.quantity -= min(selectedQuantity, stockItem.quantity)
            try? modelContext.save()
            // Delete record if user sells all stock
            if stockItem.quantity <= 0 {
                modelContext.delete(stockItem)
            }
        }
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
            
            Picker("Time Range", selection: $vm.selectedRange) {
                ForEach(ChartRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            VStack {
                HStack {
                    Stepper("Quantity: \(selectedQuantity)", value: $selectedQuantity, in: 1...1000)
                    
                    Button("Buy") {
                        buyStock()
                    }
                    .padding(7.5)
                    .padding(.horizontal)
                    .background(.green)
                    .clipShape(.buttonBorder)
                    Button("Sell") {
                        if let stockItem = getUserStock() {
                            if selectedQuantity > stockItem.quantity {
                                showAlert = true
                            } else {
                                sellStock()
                            }
                        }
                    }
                    .padding(7.5)
                    .padding(.horizontal)
                    .background(.red)
                    .clipShape(.buttonBorder)
                }
                .foregroundStyle(.black)
            }
            .padding(.vertical)
            Spacer()
            if let stockItem = getUserStock() {
                VStack {
                    Text("Holdings")
                        .font(.title2)
                    HStack {
                        Text("Quantity:")
                        Spacer()
                        Text("\(stockItem.quantity)")
                    }
                    HStack {
                        Text("Value:")
                        Spacer()
                        if let previousClose = vm.previousClose {
                            Text("$\(String(format: "%.2f", Double(stockItem.quantity) * previousClose.c))")
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle(vm.ticker)
        .task { await vm.fetchData() }
        .alert("Error", isPresented: $showAlert, presenting: selectedQuantity) { quantity in
            Button(role: .destructive) {
                sellStock()
            } label: {
                Text("Sell")
            }
            Button("Cancel", role: .cancel) {
                // Do nothing
            }
        } message: { quantity in
            Text("You have tried to sell more stock than you own. You can continue to sell as many as you have (\(getUserStock()?.quantity ?? 0)) or cancel the action.")
        }
    }
}

#Preview {
    ChartDetailView(ticker: "AAPL", apiKey: "API_KEY")
}
