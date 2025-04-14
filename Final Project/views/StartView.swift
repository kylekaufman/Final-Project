//
//  StartView.swift
//
//  Created by Emmanuel Makoye on 3/1/25.
//

import SwiftUI

struct StartView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
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
        }
    }
    
    // MARK: - Guest Action
    private func continueAsGuest() {
        authManager.currentUser = Profile(
            userId: UUID().uuidString,
            username: "Guest\(Int.random(in: 1000...9999))",
            email: "guest+\(Int.random(in: 1000...9999))@stoky.com",
            role: UserRole.guest,
            status: "active",
            firstName: "Guest",
            lastName: "User",
            phoneNumber: "000-000-\(Int.random(in: 1000...9999))",
            profilePictureURL: ""
        )
    }
}

// MARK: - Preview
#Preview("Light Mode") {
    StartView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    StartView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.dark)
}
