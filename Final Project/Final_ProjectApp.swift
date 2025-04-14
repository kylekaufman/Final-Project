//
//  Final_ProjectApp.swift
//  Final Project
//
//  Created by Kyle Kaufman on 2/20/25.
//

import SwiftUI
import SwiftData

@main
struct Final_ProjectApp: App {
    @StateObject private var authManager = AuthManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: StockItem.self)
        .environmentObject(authManager)
    }
}
