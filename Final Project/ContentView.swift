//
//  ContentView.swift
//  Final Project
//
//  Created by Kyle Kaufman on 2/20/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
        
        var body: some View {
            if authManager.currentUser == nil {
                StartView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            } else {
                HomeView()
                    .environmentObject(authManager)
            }
        }
    }

    // MARK: - Home view
    struct HomeView: View {
        @EnvironmentObject private var authManager: AuthManager
        
        var body: some View {
            TabView {
                StockListView(apiKey: "API_KEY")
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
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
}
