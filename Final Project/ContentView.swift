//
//  ContentView.swift
//  Final Project
//
//  Created by Kyle Kaufman on 2/20/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Discover", systemImage: "magnifyingglass") {
                StockListView(apiKey: "API_KEY")
            }
            
            Tab("Profile", systemImage: "person.circle.fill") {
//                ProfileView()
            }
        }
    }
}

#Preview {
    ContentView()
}
