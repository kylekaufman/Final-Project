//
//  Stock.swift
//  Final Project
//
//  Created by Alex Wang on 4/12/25.
//

import Foundation
import SwiftData

@Model
class StockItem {
    @Attribute(.unique) var ticker: String // Use as id, saving StockItem with same ticker name will throw error on save()
    var quantity: Int
    
    init(ticker: String, quantity: Int = 0) {
        self.ticker = ticker
        self.quantity = quantity
    }
}
