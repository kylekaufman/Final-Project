//
//  StockListView.swift
//  Final Project
//
//  Created by Emmanuel Makoye on 4/7/25.
//


import SwiftUI
import Charts

struct StockListView: View {
    let apiKey: String
    @State private var searchText = ""
    @State private var searchResults: [PolygonTicker] = []
    @State private var defaultTickers: [String] = ["AAPL", "GOOGL", "MSFT", "TSLA", "AMZN"] {
        didSet {
            saveDefaultTickers()
            Task { await fetchDefaultTickerData() }
        }
    }
    @State private var tickerData: [String: PolygonPreviousClose] = [:]
    @State private var chartViewModels: [String: ChartViewModel] = [:] // Store ChartViewModels for tickers
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Favorites List with fixed height
                List {
                    if searchText.isEmpty {
                        Section(header: HStack {
                            Text("Stock")
                                .font(.headline)
                                .frame(width: 80, alignment: .leading)
                            Spacer()
                            Text("Price")
                                .font(.headline)
                                .frame(width: 80, alignment: .trailing)
                            Text("Change")
                                .font(.headline)
                                .frame(width: 100, alignment: .trailing)
                        }) {
                                ForEach(defaultTickers, id: \.self) { ticker in
                                    NavigationLink(destination: ChartDetailView(ticker: ticker, apiKey: apiKey)) {
                                        HStack {
                                            Text(ticker)
                                                .font(.body)
                                                .frame(width: 80, alignment: .leading)
                                            
                                            if let data = tickerData[ticker] {
                                                Spacer()
                                                Text("$\(data.c, specifier: "%.2f")")
                                                    .font(.body)
                                                    .frame(width: 80, alignment: .trailing)
                                                
                                                let change = data.c - data.o
                                                let percentChange = (change / data.o) * 100
                                                Text("\(percentChange >= 0 ? "+" : "")\(percentChange, specifier: "%.2f")%")
                                                    .font(.body)
                                                    .foregroundColor(change >= 0 ? .green : .red)
                                                    .frame(width: 100, alignment: .trailing)
                                            } else {
                                                Spacer()
                                                Text("Loading...")
                                                    .font(.body)
                                                    .foregroundColor(.gray)
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                            }
                                        }
                                    }

                            }
                                .onDelete(perform: { indexSet in
                                    withAnimation {
                                        deleteTickers(at: indexSet)
                                    }
                                })
                        }
                    }
                    
                    if !searchResults.isEmpty {
                        Section(header: Text("Search Results")) {
                            ForEach(searchResults, id: \.ticker) {ticker in
                                HStack {
                                    NavigationLink(destination: ChartDetailView(ticker: ticker.ticker, apiKey: apiKey)) {
                                        VStack(alignment: .leading) {
                                            Text(ticker.ticker)
                                                .font(.headline)
                                            Text(ticker.name)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        if defaultTickers.contains(ticker.ticker) {
                                            defaultTickers.removeAll { $0 == ticker.ticker }
                                        } else {
                                            addTicker(ticker.ticker)
                                        }
                                    }) {
                                        Image(systemName: defaultTickers.contains(ticker.ticker) ? "minus.circle" : "plus.circle")
                                            .font(.system(size: 24))
                                            .foregroundColor(defaultTickers.contains(ticker.ticker) ? .red : .green)
                                    }
                                    .buttonStyle(.borderless)
                                    .frame(width: 30, height: 30)
                                }
                            }
                            .listRowInsets(EdgeInsets())
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("STOKY")
                .searchable(text: $searchText, prompt: "Search for a stock (e.g., AAPL)")
                .onChange(of: searchText) { _, newValue in
                    Task {
                        await performSearch(query: newValue)
                    }
                }
            
                // Charts for the first three favorite tickers
                    /*
                    VStack(spacing: 150) {
                        ForEach(defaultTickers.prefix(1), id: \.self) { ticker in
                            if let vm = chartViewModels[ticker], let chartData = vm.chart {
                                VStack(alignment: .leading) {
                                    Text(ticker)
                                        .font(.headline)
                                        .padding(.leading)
                                    ChartView(data: chartData, vm: vm)
                                        .frame(height: 100) // Smaller height for preview charts
                                }
                            } else {
                                Text("Loading chart for \(ticker)...")
                                    .frame(height: 100)
                            }
                        }
                    }
                    .padding()
                    */
                }
            }
        .onAppear {
            loadDefaultTickers()
            Task { await fetchDefaultTickerData() }
            setupChartViewModels()
        }
        .onChange(of: defaultTickers) { _, _ in
            setupChartViewModels()
        }
    }
    
    // Setup ChartViewModels for favorite tickers
    private func setupChartViewModels() {
        for ticker in defaultTickers {
            if chartViewModels[ticker] == nil {
                let vm = ChartViewModel(ticker: ticker, apiKey: apiKey)
                chartViewModels[ticker] = vm
                Task { await vm.fetchData() }
            }
        }
        // Remove view models for tickers no longer in favorites
        chartViewModels = chartViewModels.filter { defaultTickers.contains($0.key) }
    }
    
    // Delete tickers from default list
    private func deleteTickers(at offsets: IndexSet) {
        defaultTickers.remove(atOffsets: offsets)
    }
    
    // Add ticker to default list
    private func addTicker(_ ticker: String) {
        if !defaultTickers.contains(ticker) {
            defaultTickers.append(ticker)
        }
    }
    
    // Perform search
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        do {
            let results = try await searchTickers(query: query, apiKey: apiKey)
            searchResults = results
        } catch {
            print("Search failed: \(error)")
            searchResults = []
        }
    }
    
    // Fetch price data for default tickers
    private func fetchDefaultTickerData() async {
        for ticker in defaultTickers {
            do {
                if let data = try await fetchPreviousClose(ticker: ticker, apiKey: apiKey) {
                    tickerData[ticker] = data
                }
            } catch {
                print("Failed to fetch data for \(ticker): \(error)")
            }
        }
    }
    
    // Persist default tickers to UserDefaults
    private func saveDefaultTickers() {
        UserDefaults.standard.set(defaultTickers, forKey: "defaultTickers")
    }
    
    // Load default tickers from UserDefaults
    private func loadDefaultTickers() {
        if let savedTickers = UserDefaults.standard.array(forKey: "defaultTickers") as? [String] {
            defaultTickers = savedTickers
        }
    }
}

#Preview {
    StockListView(apiKey: Config.apiKey)
}
