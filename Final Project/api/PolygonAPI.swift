//
//  PolygonAPI.swift
//  Final Project
//
//  Created by Emmanuel Makoye on 4/6/25.
//

import Foundation

// Historical Data (Aggregates)
struct PolygonAggsResponse: Codable {
    let results: [PolygonOHLC]
}

struct PolygonOHLC: Codable {
    let t: Int64  // timestamp in milliseconds
    let c: Double // close price
}

func fetchHistoricalChartData(ticker: String, from: String, to: String, multiplier: Int, timespan: String, apiKey: String) async throws -> [ChartViewItem] {
        let urlString = "https://api.polygon.io/v2/aggs/ticker/\(ticker)/range/\(multiplier)/\(timespan)/\(from)/\(to)?adjusted=true&sort=asc&apiKey=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PolygonAggsResponse.self, from: data)
        
        return response.results.map { result in
            ChartViewItem(
                timestamp: Date(timeIntervalSince1970: TimeInterval(result.t / 1000)),
                value: result.c
            )
        }
    }

// Quote (Previous Close)
struct PolygonPreviousCloseResponse: Codable {
    let results: [PolygonPreviousClose]
}

struct PolygonPreviousClose: Codable {
    let c: Double // Close price
    let h: Double // High price
    let l: Double // Low price
    let o: Double // Open price
    let t: Int64  // Timestamp in milliseconds
}

func fetchPreviousClose(ticker: String, apiKey: String) async throws -> PolygonPreviousClose? {
    let urlString = "https://api.polygon.io/v2/aggs/ticker/\(ticker)/prev?adjusted=true&apiKey=\(apiKey)"
    
    guard let url = URL(string: urlString) else { return nil }
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoded = try JSONDecoder().decode(PolygonPreviousCloseResponse.self, from: data)
    
    return decoded.results.first // Return the first result (most recent previous close)
}

// Ticker Search
struct PolygonTickerSearchResponse: Codable {
    let results: [PolygonTicker]
}

struct PolygonTicker: Codable {
    let ticker: String
    let name: String
    let market: String
    let locale: String
    let primaryExchange: String?
    let type: String?
    let active: Bool
    let currency: String?
    
    enum CodingKeys: String, CodingKey {
        case ticker
        case name
        case market
        case locale
        case primaryExchange = "primary_exchange"
        case type
        case active
        case currency = "currency_name"
    }
}

func searchTickers(query: String, apiKey: String, limit: Int = 10) async throws -> [PolygonTicker] {
    let urlString = "https://api.polygon.io/v3/reference/tickers?search=\(query)&limit=\(limit)&apiKey=\(apiKey)"
    
    guard let url = URL(string: urlString) else { return [] }
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoded = try JSONDecoder().decode(PolygonTickerSearchResponse.self, from: data)
    
    return decoded.results
}
