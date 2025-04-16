//
//  TransactionData.swift
//  Final Project
//
//  Created by Mufu Tebit on 4/15/25.
//


import Foundation
import SwiftData

/// Transaction types supported in the app
enum TransactionType: String, Codable {
    case deposit = "Deposit"
    case buy = "Buy"
    case sell = "Sell"
}

/// Model to track financial transactions in the app
@Model
final class TransactionData {
    // IMPORTANT: Make sure these are all stored properties, not computed
    @Attribute(.unique) var id: String
    var userId: String
    var type: String
    var amount: Double
    var ticker: String?
    var quantity: Int?
    var pricePerShare: Double?
    var timestamp: Date
    
    /// Description of the transaction
    var description: String {
        switch TransactionType(rawValue: type) {
        case .deposit:
            return "Deposited $\(String(format: "%.2f", amount))"
        case .buy:
            if let ticker = ticker, let quantity = quantity, let pricePerShare = pricePerShare {
                return "Bought \(quantity) shares of \(ticker) at $\(String(format: "%.2f", pricePerShare))"
            }
            return "Unknown buy transaction"
        case .sell:
            if let ticker = ticker, let quantity = quantity, let pricePerShare = pricePerShare {
                return "Sold \(quantity) shares of \(ticker) at $\(String(format: "%.2f", pricePerShare))"
            }
            return "Unknown sell transaction"
        case nil:
            return "Unknown transaction"
        }
    }
    
    init(
        id: String,
        userId: String,
        type: TransactionType,
        amount: Double,
        ticker: String? = nil,
        quantity: Int? = nil,
        pricePerShare: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type.rawValue
        self.amount = amount
        self.ticker = ticker
        self.quantity = quantity
        self.pricePerShare = pricePerShare
        self.timestamp = timestamp
    }
}
