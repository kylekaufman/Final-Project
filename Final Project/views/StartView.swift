//
//  StartView.swift
//
//  Created by Emmanuel Makoye on 3/1/25.
//


import SwiftUI
import SwiftData

struct StartView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var showingPersistenceTest = false
    @State private var persistenceMessage = ""
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.blue.opacity(0.8) : Color.blue,
                colorScheme == .dark ? Color.purple.opacity(0.8) : Color.purple
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // App Logo/Name
                    VStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        Text("STOKY")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    
                    // Welcome Message
                    Text("Trade And Manage Your Stocks!")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    // Action Buttons
                    VStack(spacing: 20) {
                        NavigationLink(destination: LoginView()) {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    Color.blue
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                                )
                        }
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .font(.headline)
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    Color.white
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                                )
                        }
                        
                        Button(action: continueAsGuest) {
                            Text("Continue as Guest")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    Color.clear
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding(.top, 60)
            }
            .navigationBarHidden(true)
            .onAppear {
                // Provide the model context to the auth manager
                authManager.setModelContext(modelContext)
                
                // Try to restore previous guest session
                if authManager.restoreLastGuestUser() {
                    print("Restored previous guest session")
                }
            }
            .alert("User Data Persistence Test", isPresented: $showingPersistenceTest) {
                Button("Continue") {
                    showingPersistenceTest = false
                }
            } message: {
                Text(persistenceMessage)
            }
        }
    }
    
    // MARK: - Guest Action
    private func continueAsGuest() {
        // Always create a new guest user (old one was deleted during logout)
        authManager.createGuestUser()
        testDataPersistence(wasRestored: false)
    }
    
    // Test if the data was persisted correctly
    private func testDataPersistence(wasRestored: Bool) {
        if let userData = authManager.userSwiftDataModel {
            if wasRestored {
                persistenceMessage = "Successfully restored previous guest user: \(userData.username) with account balance: $\(String(format: "%.2f", userData.accountBalance))"
            } else {
                persistenceMessage = "New guest user created and persisted: \(userData.username) with starting balance: $\(String(format: "%.2f", userData.accountBalance))"
            }
        } else {
            persistenceMessage = "Warning: User created but data persistence failed."
        }
        
        showingPersistenceTest = true
    }
}

// MARK: - Preview
#Preview("Light Mode") {
    StartView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.light)
        .modelContainer(for: [UserData.self, StockItem.self])
}

#Preview("Dark Mode") {
    StartView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.dark)
        .modelContainer(for: [UserData.self, StockItem.self])
}
