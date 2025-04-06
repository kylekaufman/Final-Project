//
//  StockListView.swift
//  Final Project
//
//  Created by Emmanuel Makoye on 4/6/25.
//

import SwiftUI

struct StockListView: View {
    let apiKey: String
    @State private var searchText = ""
    @State private var searchResults: [PolygonTicker] = []
    @State private var defaultTickers: [String] = ["AAPL", "GOOGL", "MSFT", "TSLA", "AMZN"] {
        didSet {
            saveDefaultTickers()
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Default Tickers Section (shown only when searchText is empty)
                if searchText.isEmpty {
                    Section(header: Text("Favorites")) {
                        ForEach(defaultTickers, id: \.self) { ticker in
                            NavigationLink(destination: ChartDetailView(ticker: ticker, apiKey: apiKey)) {
                                Text(ticker)
                                    .font(.headline)
                            }
                        }
                        .onDelete(perform: deleteTickers)
                    }
                }
                
                // Search Results Section (shown when there are results)
                if !searchResults.isEmpty {
                    Section(header: Text("Search Results")) {
                        ForEach(searchResults, id: \.ticker) { ticker in
                            HStack {
                                NavigationLink(destination: ChartDetailView(ticker: ticker.ticker, apiKey: apiKey)) {
                                    VStack(alignment: .leading) {
                                        Text(ticker.ticker)
                                            .font(.headline)
                                        Text(ticker.name)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                                Button(action: {
                                    addTicker(ticker.ticker)
                                }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stocks")
            .searchable(text: $searchText, prompt: "Search for a ticker (e.g., AAPL)")
            .onChange(of: searchText) { newValue in
                Task {
                    await performSearch(query: newValue)
                }
            }
        }
        .onAppear {
            loadDefaultTickers()
        }
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
    StockListView(apiKey: "API_KEY")
}
