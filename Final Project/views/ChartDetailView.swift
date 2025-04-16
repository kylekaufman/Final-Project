import SwiftUI
import SwiftData

struct ChartDetailView: View {
    @StateObject private var vm: ChartViewModel
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var selectedQuantity: Int = 1
    @Environment(\.modelContext) private var modelContext
    @Query private var portfolio: [StockItem] // All currently held stocks
    @EnvironmentObject private var authManager: AuthManager
    
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
            
            Picker("Time Range", selection: $vm.selectedRange) {
                ForEach(ChartRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            // Account Balance (New)
            if let userData = authManager.userSwiftDataModel {
                HStack {
                    Text("Account Balance:")
                    Spacer()
                    Text("$\(String(format: "%.2f", userData.accountBalance))")
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Allow user to simulate buying/selling stocks
            VStack {
                HStack {
                    Stepper("Quantity: \(selectedQuantity)", value: $selectedQuantity, in: 1...1000)
                    
                    Button("Buy") {
                        buyStock()
                    }
                    .padding(7.5)
                    .padding(.horizontal)
                    .background(.green)
                    .foregroundColor(.white)
                    .clipShape(.buttonBorder)
                    
                    Button("Sell") {
                        sellStock()
                    }
                    .padding(7.5)
                    .padding(.horizontal)
                    .background(.red)
                    .foregroundColor(.white)
                    .clipShape(.buttonBorder)
                }
            }
            .padding(.vertical)
            
            Spacer()
            
            // Show info about user's holding in this particular stock
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
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding()
            }
        }
        .padding()
        .navigationTitle(vm.ticker)
        .task { await vm.fetchData() }
        .alert("Stock Transaction", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func getUserStock() -> StockItem? {
        return portfolio.filter { $0.ticker == vm.ticker }.first
    }
    
    private func buyStock() {
        guard let previousClose = vm.previousClose else {
            alertMessage = "Cannot buy: Stock price unavailable"
            showAlert = true
            return
        }
        
        let totalCost = previousClose.c * Double(selectedQuantity)
        
        // Check if user has enough funds
        guard let userData = authManager.userSwiftDataModel, userData.accountBalance >= totalCost else {
            alertMessage = "Insufficient funds for this purchase"
            showAlert = true
            return
        }
        
        // Update user balance
        let newBalance = userData.accountBalance - totalCost
        _ = authManager.updateAccountBalance(
            amount: newBalance,
            transactionType: .buy,
            ticker: vm.ticker,
            quantity: selectedQuantity,
            pricePerShare: previousClose.c
        )
        
        // Update stock holdings
        if let stockItem = getUserStock() {
            stockItem.quantity += selectedQuantity
            try? modelContext.save()
        } else {
            modelContext.insert(StockItem(ticker: vm.ticker, quantity: selectedQuantity))
        }
        
        alertMessage = "Successfully purchased \(selectedQuantity) shares of \(vm.ticker) for $\(String(format: "%.2f", totalCost))"
        showAlert = true
    }
    
    private func sellStock() {
        guard let stockItem = getUserStock() else {
            alertMessage = "You don't own any shares of \(vm.ticker)"
            showAlert = true
            return
        }
        
        // Don't allow selling more than owned
        if selectedQuantity > stockItem.quantity {
            alertMessage = "You only have \(stockItem.quantity) shares to sell"
            showAlert = true
            return
        }
        
        guard let previousClose = vm.previousClose else {
            alertMessage = "Cannot sell: Stock price unavailable"
            showAlert = true
            return
        }
        
        let totalValue = previousClose.c * Double(selectedQuantity)
        
        // Update user balance
        if let userData = authManager.userSwiftDataModel {
            let newBalance = userData.accountBalance + totalValue
            _ = authManager.updateAccountBalance(
                amount: newBalance,
                transactionType: .sell,
                ticker: vm.ticker,
                quantity: selectedQuantity,
                pricePerShare: previousClose.c
            )
        }
        
        // Update stock holdings
        stockItem.quantity -= selectedQuantity
        
        // Delete record if user sells all stock
        if stockItem.quantity <= 0 {
            modelContext.delete(stockItem)
        }
        
        try? modelContext.save()
        
        alertMessage = "Successfully sold \(selectedQuantity) shares of \(vm.ticker) for $\(String(format: "%.2f", totalValue))"
        showAlert = true
    }
}

#Preview {
    ChartDetailView(ticker: "AAPL", apiKey: Config.apiKey)
        .environmentObject(AuthManager())
        .modelContainer(for: [UserData.self, StockItem.self])
}
