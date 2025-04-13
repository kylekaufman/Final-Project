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
    @Attribute(.unique) var ticker: String
    var quantity: Int
    
    init(ticker: String, quantity: Int = 0) {
        self.ticker = ticker
        self.quantity = quantity
    }
}
