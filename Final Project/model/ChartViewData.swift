//
//  ChartViewData.swift
//  Final Project
//
//  Created by Emmanuel Makoye on 4/6/25.
//


import Foundation
import SwiftUI

struct ChartViewData: Identifiable, Equatable {
    let id = UUID()
    let xAxisData: ChartAxisData
    let yAxisData: ChartAxisData
    let items: [ChartViewItem]
    let lineColor: Color
    let previousCloseRuleMarkValue: Double?
    
    // Implement Equatable conformance
    static func == (lhs: ChartViewData, rhs: ChartViewData) -> Bool {
        return lhs.xAxisData == rhs.xAxisData &&
               lhs.yAxisData == rhs.yAxisData &&
               lhs.items == rhs.items &&
               lhs.lineColor == rhs.lineColor &&
               lhs.previousCloseRuleMarkValue == rhs.previousCloseRuleMarkValue
        // Note: We exclude 'id' from comparison since it’s a unique identifier
    }
}

struct ChartAxisData: Equatable {
    let axisStart: Double
    let axisEnd: Double
    let strideBy: Double
    let map: [String: String]
    
    // Equatable is automatically synthesized for this struct since all properties are Equatable
}

struct ChartViewItem: Identifiable, Equatable, Codable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    
    // Implement Equatable conformance
    static func == (lhs: ChartViewItem, rhs: ChartViewItem) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
               lhs.value == rhs.value
        // Note: We exclude 'id' from comparison since it’s a unique identifier
    }
}
