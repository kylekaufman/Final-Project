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
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init() {
        // Apply appearance on launch
        AppearanceManager.shared.applyAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear {
                    // Enable SwiftData debug logging
                    UserDefaults.standard.set(true, forKey: "_SwiftDataShowQueryLog")
                }
        }
        .modelContainer(for: [StockItem.self, UserData.self, TransactionData.self],
                       inMemory: false,
                       isAutosaveEnabled: true)
        .environmentObject(authManager)
    }
}
