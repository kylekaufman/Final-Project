//
//  ContentView.swift
//  Final Project
//
//  Created by Kyle Kaufman on 2/20/25.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if authManager.currentUser == nil {
                StartView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            } else {
                HomeView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // Inject the model context into the auth manager
            authManager.setModelContext(modelContext)
            
            // Setup the database for transactions if needed
            setupDatabase()
            
            // Try to restore a previous guest session on app start
            if authManager.currentUser == nil {
                _ = authManager.restoreLastGuestUser()
            }
        }
    }
    
    // Setup database schema and migration if needed
    private func setupDatabase() {
        print("Setting up database schema...")
        
        do {
            // This will help trigger schema setup
            let descriptor = FetchDescriptor<TransactionData>()
            let _ = try modelContext.fetch(descriptor)
            print("Transaction schema loaded successfully")
        } catch {
            print("Transaction schema setup error: \(error)")
        }
    }
}

// MARK: - Home view
struct HomeView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        TabView {
            StockListView(apiKey: Config.apiKey)
                .tabItem {
                    Label("Stocks", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .accentColor(.purple)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .modelContainer(for: [UserData.self, StockItem.self])
}
