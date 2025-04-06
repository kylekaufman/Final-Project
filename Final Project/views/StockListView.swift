import SwiftUI

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
    
    var body: some View {
        NavigationStack {
            List {
                // Default Tickers Section (shown only when searchText is empty)
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
            Task { await fetchDefaultTickerData() }
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
    StockListView(apiKey: "API_KEY")
}
