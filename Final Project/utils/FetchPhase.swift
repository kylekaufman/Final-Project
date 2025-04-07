import Charts
import Foundation
import SwiftUI

enum FetchPhase<T>: Equatable where T: Equatable {
    case initial
    case fetching
    case success(T)
    case failure(Error)
    case empty
    
    var value: T? {
        switch self {
        case .success(let data):
            return data
        default:
            return nil
        }
    }
    
    static func == (lhs: FetchPhase<T>, rhs: FetchPhase<T>) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial), (.fetching, .fetching), (.empty, .empty):
            return true
        case (.success(let left), .success(let right)):
            return left == right
        case (.failure, .failure):
            return true
        default:
            return false
        }
    }
}

enum ChartRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case lastFiveDays = "5D"
    case lastMonth = "1M"
    case lastYear = "1Y"
    case lastFiveYears = "5Y"
    
    var id: String { rawValue }
    
    var dateFormat: String {
        switch self {
        case .today: return "HH:mm"
        case .lastFiveDays: return "MM/dd HH:mm"
        case .lastMonth, .lastYear, .lastFiveYears: return "MM/dd/yy"
        }
    }
    
    var daysBack: Int {
        switch self {
        case .today: return 0
        case .lastFiveDays: return 5
        case .lastMonth: return 30
        case .lastYear: return 365
        case .lastFiveYears: return 365 * 5
        }
    }
    var timespan: String {
            switch self {
            case .today: return "minute"
            case .lastFiveDays: return "hour"
            case .lastMonth: return "day"
            case .lastYear, .lastFiveYears: return "day"
            }
        }
    
    var multiplier: Int {
            switch self {
            case .today: return 5
            case .lastFiveDays: return 1
            case .lastMonth: return 1
            case .lastYear: return 1
            case .lastFiveYears: return 5
            }
        }
}

@MainActor
class ChartViewModel: ObservableObject {
    @Published var fetchPhase = FetchPhase<ChartViewData>.initial
    @Published var previousClose: PolygonPreviousClose?
    var chart: ChartViewData? { fetchPhase.value }
    
    @Published var ticker: String {
        didSet {
            Task { await fetchData() }
        }
    }
    let apiKey: String
    
    @Published var selectedRange: ChartRange = .today {
        didSet {
            Task { await fetchData() }
        }
    }
    @Published var selectedX: (any Plottable)?
    
    var selectedXRuleMark: (value: Int, text: String)? {
        guard let selectedX = selectedX as? Int, let chart else { return nil }
        return (selectedX, chart.items[selectedX].value.roundedString)
    }
    
    var foregroundMarkColor: Color {
        (selectedX != nil) ? .cyan : (chart?.lineColor ?? .cyan)
    }
    
    // Calculate change and percentage change based on chart data
    var priceChange: Double? {
        guard let chart = chart, let first = chart.items.first?.value, let last = chart.items.last?.value else { return nil }
        return last - first
    }
    
    var percentChange: Double? {
        guard let chart = chart, let first = chart.items.first?.value, let last = chart.items.last?.value, first != 0 else { return nil }
        return ((last - first) / first) * 100
    }
    
    private let dateFormatter = DateFormatter()
    private let selectedValueDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    private let maxEntries = 100
    
    init(ticker: String, apiKey: String) {
        self.ticker = ticker
        self.apiKey = apiKey
    }
    
    func fetchData() async {
            do {
                fetchPhase = .fetching
                
                // Fetch previous close (optional, for reference)
                previousClose = try await fetchPreviousClose(ticker: ticker, apiKey: apiKey)
                
                let toDate = Date()
                let fromDate: Date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                // For "Today", use the current date as both from and to
                if selectedRange == .today {
                    fromDate = Calendar.current.startOfDay(for: toDate)
                } else {
                    fromDate = Calendar.current.date(byAdding: .day, value: -selectedRange.daysBack, to: toDate)!
                }
                
                let from = dateFormatter.string(from: fromDate)
                let to = dateFormatter.string(from: toDate)
                
                // Check cache first
                if let cachedItems = loadFromFile(for: selectedRange) {
                    print("Loaded \(cachedItems.count) items from file for \(ticker) \(selectedRange.rawValue)")
                    if !cachedItems.isEmpty {
                        fetchPhase = .success(transformChartViewData(cachedItems))
                        return
                    }
                }
                
                // Fetch historical data with appropriate timespan
                let items = try await fetchHistoricalChartData(
                    ticker: ticker,
                    from: from,
                    to: to,
                    multiplier: selectedRange.multiplier,
                    timespan: selectedRange.timespan,
                    apiKey: apiKey
                )
                
                guard !items.isEmpty else {
                    print("Empty API response for \(ticker)")
                    fetchPhase = .empty
                    return
                }
                
                saveToFile(items, for: selectedRange)
                fetchPhase = .success(transformChartViewData(items))
            } catch {
                print("Failed to fetch for \(ticker): \(error)")
                fetchPhase = .failure(error)
            }
        }
    
    func transformChartViewData(_ items: [ChartViewItem]) -> ChartViewData {
        let (xAxisChartData, chartItems) = xAxisChartDataAndItems(items)
        let yAxisChartData = yAxisChartData(items)
        return ChartViewData(
            xAxisData: xAxisChartData,
            yAxisData: yAxisChartData,
            items: chartItems,
            lineColor: getLineColor(items: items),
            previousCloseRuleMarkValue: nil
        )
    }
    
    func xAxisChartDataAndItems(_ items: [ChartViewItem]) -> (ChartAxisData, [ChartViewItem]) {
        dateFormatter.dateFormat = selectedRange.dateFormat
        var map = [String: String]()
        
        for (index, item) in items.enumerated() {
            map[String(index)] = dateFormatter.string(from: item.timestamp)
        }
        
        let strideBy = max(1, Double(items.count / 5))
        let xAxisData = ChartAxisData(
            axisStart: 0,
            axisEnd: Double(items.count - 1),
            strideBy: strideBy,
            map: map
        )
        
        return (xAxisData, items)
    }
    
    func yAxisChartData(_ items: [ChartViewItem]) -> ChartAxisData {
        let closes = items.map { $0.value }
        let lowest = closes.min() ?? 0
        let highest = closes.max() ?? 0
        let diff = highest - lowest
        let numberOfLines: Double = 4
        let strideBy: Double = diff / numberOfLines
        
        var map = [String: String]()
        var current = lowest
        while current <= highest {
            map[current.roundedString] = String(format: "%.2f", current)
            current += strideBy
        }
        
        return ChartAxisData(
            axisStart: lowest - (strideBy * 0.1),
            axisEnd: highest + (strideBy * 0.1),
            strideBy: strideBy,
            map: map
        )
    }
    
    func getLineColor(items: [ChartViewItem]) -> Color {
        guard let first = items.first?.value, let last = items.last?.value else { return .blue }
        return last >= first ? .green : .red
    }
    
    private func fileURL(for range: ChartRange) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("\(ticker)_\(range.rawValue).json")
    }
    
    private func loadFromFile(for range: ChartRange) -> [ChartViewItem]? {
        let fileURL = fileURL(for: range)
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode([ChartViewItem].self, from: data)
        } catch {
            print("Failed to load from file for \(ticker) \(range.rawValue): \(error)")
            return nil
        }
    }
    
    private func saveToFile(_ items: [ChartViewItem], for range: ChartRange) {
        let fileURL = fileURL(for: range)
        do {
            var existingItems = loadFromFile(for: range) ?? []
            existingItems.append(contentsOf: items)
            
            if existingItems.count > maxEntries {
                existingItems.removeFirst(5)
            }
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(existingItems)
            try data.write(to: fileURL, options: .atomic)
            print("Saved \(existingItems.count) items to file for \(ticker) \(range.rawValue)")
        } catch {
            print("Failed to save to file for \(ticker) \(range.rawValue): \(error)")
        }
    }
}

extension Double {
    var roundedString: String { String(format: "%.2f", self) }
}
