//
//  PortfolioView.swift
//  Final Project
//
//  Created by Mufu Tebit on 4/15/25.
//


import SwiftUI
import SwiftData
import Charts

struct PortfolioView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Query private var portfolio: [StockItem]
    
    @State private var depositAmount: String = ""
    @State private var showingDepositView = false
    @State private var showingTransactions = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Dictionary to store stock prices
    @State private var stockPrices: [String: Double] = [:]
    @State private var isLoadingPrices = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Account Balance Card
                    if let userData = authManager.userSwiftDataModel {
                        AccountBalanceCard(
                            balance: userData.accountBalance,
                            onDepositTapped: { showingDepositView = true }
                        )
                    }
                    
                    // Portfolio Distribution Chart
                    VStack(alignment: .leading) {
                        Text("Portfolio Distribution")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if portfolio.isEmpty {
                            EmptyPortfolioView()
                        } else if isLoadingPrices {
                            ProgressView("Loading portfolio data...")
                                .frame(height: 300)
                        } else {
                            PortfolioChart(portfolio: portfolio, stockPrices: stockPrices)
                                .frame(height: 300)
                                .padding()
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Holdings List
                    VStack(alignment: .leading) {
                        Text("Your Holdings")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if portfolio.isEmpty {
                            Text("You don't own any stocks yet")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(portfolio) { stock in
                                HoldingRow(
                                    ticker: stock.ticker,
                                    quantity: stock.quantity,
                                    price: stockPrices[stock.ticker] ?? 0
                                )
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Transactions Button
                Button(action: {
                    showingTransactions = true
                }) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Transaction History")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Portfolio")
            .onAppear {
                fetchStockPrices()
            }
            .refreshable {
                fetchStockPrices()
            }
            .sheet(isPresented: $showingDepositView) {
                DepositView { amount in
                    processDepositWithAmount(amount)
                }
            }
            .sheet(isPresented: $showingTransactions) {
                TransactionHistoryView()
            }
            .alert("Portfolio Update", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // Process deposit with direct amount
    private func processDepositWithAmount(_ amount: Double) {
        if amount <= 0 {
            alertMessage = "Please enter a valid amount greater than zero."
            showAlert = true
            return
        }
        
        if let userData = authManager.userSwiftDataModel {
            let newBalance = userData.accountBalance + amount
            if authManager.updateAccountBalance(
                amount: newBalance,
                transactionType: .deposit
            ) != nil {
                alertMessage = "Successfully deposited $\(String(format: "%.2f", amount))"
            } else {
                alertMessage = "Failed to process deposit. Please try again."
            }
            showAlert = true
        }
    }
    
    // Legacy deposit process (no longer used)
    private func processDeposit() {
        guard let amount = Double(depositAmount), amount > 0 else {
            depositAmount = ""
            alertMessage = "Please enter a valid amount greater than zero."
            showAlert = true
            return
        }
        
        if let userData = authManager.userSwiftDataModel {
            let newBalance = userData.accountBalance + amount
            if authManager.updateAccountBalance(amount: newBalance) != nil {
                alertMessage = "Successfully deposited $\(String(format: "%.2f", amount))"
            } else {
                alertMessage = "Failed to process deposit. Please try again."
            }
            showAlert = true
        }
        
        depositAmount = ""
    }
    
    // Fetch stock prices for portfolio
    private func fetchStockPrices() {
        guard !portfolio.isEmpty else { return }
        
        isLoadingPrices = true
        stockPrices = [:]
        
        let apiKey = Config.apiKey
        
        // Create a task group to fetch prices in parallel
        Task {
            for stock in portfolio {
                do {
                    if let data = try await fetchPreviousClose(ticker: stock.ticker, apiKey: apiKey) {
                        await MainActor.run {
                            stockPrices[stock.ticker] = data.c
                        }
                    }
                } catch {
                    print("Failed to fetch price for \(stock.ticker): \(error)")
                }
            }
            
            await MainActor.run {
                isLoadingPrices = false
            }
        }
    }
}

// MARK: - Supporting Views

// Account Balance Card
struct AccountBalanceCard: View {
    let balance: Double
    let onDepositTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Account Balance")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("$\(String(format: "%.2f", balance))")
                .font(.system(size: 36, weight: .bold))
            
            Button(action: onDepositTapped) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Deposit Funds")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// Portfolio Chart
struct PortfolioChart: View {
    let portfolio: [StockItem]
    let stockPrices: [String: Double]
    
    // Fixed set of chart colors to ensure consistency
    let chartColors: [Color] = [
        .blue,
        .orange,
        .green,
        .red,
        .purple,
        .yellow,
        .teal,
        .pink
    ]
    
    // Get color at specific index with wraparound for more than 8 stocks
    func getChartColor(at index: Int) -> Color {
        chartColors[index % chartColors.count]
    }
    
    var portfolioData: [PortfolioItem] {
        portfolio.compactMap { stock in
            guard let price = stockPrices[stock.ticker] else { return nil }
            return PortfolioItem(
                ticker: stock.ticker,
                value: Double(stock.quantity) * price
            )
        }
        .filter { $0.value > 0 }
    }
    
    var body: some View {
        if portfolioData.isEmpty {
            Text("Waiting for stock price data...")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack {
                Chart {
                    ForEach(Array(zip(portfolioData.indices, portfolioData)), id: \.0) { index, item in
                        SectorMark(
                            angle: .value("Value", item.value),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(getChartColor(at: index))
                    }
                }
                
                // Legend with matching colors in a grid layout
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(Array(zip(portfolioData.indices, portfolioData)), id: \.0) { index, item in
                        HStack(spacing: 4) {
                            // Use ChartColorStyle to get the same colors as the chart
                            Rectangle()
                                .fill(Color(getChartColor(at: index)))
                                .frame(width: 12, height: 12)
                            
                            Text(item.ticker)
                                .font(.caption)
                            
                            Text("(\(Int((item.value / totalValue) * 100))%)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    var totalValue: Double {
        portfolioData.reduce(0) { $0 + $1.value }
    }
}

// Portfolio Item struct for chart data
struct PortfolioItem: Identifiable {
    var id = UUID()
    let ticker: String
    let value: Double
}

// Empty Portfolio View
struct EmptyPortfolioView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("Your portfolio is empty")
                .font(.headline)
            
            Text("Start buying stocks to see your portfolio distribution")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

// Stock Holding Row
struct HoldingRow: View {
    let ticker: String
    let quantity: Int
    let price: Double
    
    var totalValue: Double {
        Double(quantity) * price
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(ticker)
                    .font(.headline)
                Text("\(quantity) shares")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(String(format: "%.2f", totalValue))")
                    .font(.headline)
                
                Text("$\(String(format: "%.2f", price)) per share")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews
#Preview {
    PortfolioView()
        .environmentObject(AuthManager())
        .modelContainer(for: [UserData.self, StockItem.self])
}
