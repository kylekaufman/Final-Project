//
//  AuthManager.swift
//  Final Project
//
//  Created by Emmanuel Makoye on 4/14/25.
//


import Foundation
import SwiftUI
import JWTDecode
import Security

// MARK: - Auth Manager
class AuthManager: ObservableObject {
    @AppStorage("authToken") private var authToken: String?
    @AppStorage("tokenExpiration") private var tokenExpiration: Double?
    private let apiBaseURL = "https://4wpft6a3qc.execute-api.us-east-2.amazonaws.com/dev/"
    
    private let isDev = ProcessInfo.processInfo.environment["NODE_ENV"] == "development"
    private let tokenLifetime: TimeInterval = 7 * 24 * 60 * 60
    
    @Published var errorMessage: String?
    @Published var idToken: String?
    @Published var isLoading: Bool = false
    @Published var currentUser: Profile?
    @Published var isAuthenticated: Bool = false
    
    init() {
            checkTokenValidity()
        }
    
    // Check if token is still valid
        private func checkTokenValidity() {
            guard let token = authToken,
                  let expiration = tokenExpiration else {
                isAuthenticated = false
                return
            }
            
            let currentTime = Date().timeIntervalSince1970
            if currentTime < expiration {
                idToken = token
                isAuthenticated = true
                Task {
                    do {
                        _ = try await getCurrentUser()
                    } catch {
                        await MainActor.run {
                            self.logout()
                        }
                    }
                }
            } else {
                logout()
            }
        }
    
    // MARK: - Sign Up
    func signup(_ data: User) async throws -> SignUpResponse {
        let url = try makeURL(endpoint: "/users/signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(data)
        } catch {
            throw AuthError.encodingFailed(error)
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let response = String(data: data, encoding: .utf8) else {
            throw AuthError.invalidResponse
        }
        
        if response.contains("UsernameExistsException") {
            throw AuthError.usernameExists
        }
        guard let stringData = response.data(using: .utf8),
              let parsedString = try JSONSerialization.jsonObject(with: stringData, options: [.allowFragments]) as? String,
              let jsonData = parsedString.data(using: .utf8),
              let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
              let finalJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
            await MainActor.run { isLoading = false }
            throw AuthError.invalidResponse
        }
        
        let signUpResponse = try JSONDecoder().decode(SignUpResponse.self, from: finalJsonData)
        
        
        return signUpResponse
    }
    // MARK: - Sign In
    func signin(_ formData: SignInFormData) async throws -> LoginResponse {
            guard !formData.username.isEmpty, !formData.password.isEmpty else {
                throw AuthError.signInFailed("Please enter username and password")
            }
            
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            let url = try makeURL(endpoint: "/users/login")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONEncoder().encode(formData)
            } catch {
                await MainActor.run { isLoading = false }
                throw AuthError.encodingFailed(error)
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run { isLoading = false }
                throw AuthError.invalidResponse
            }
            
            guard let jsonString = String(data: data, encoding: .utf8) else {
                await MainActor.run { isLoading = false }
                throw AuthError.invalidResponse
            }
        
            if jsonString.contains("UsernameExistsException") {
                throw AuthError.usernameExists
            }
            if jsonString.contains("UserNotFoundException") {
                throw AuthError.userNotFound("user not found")
            }
            if jsonString.contains("NotAuthorizedException") {
                throw AuthError.invalidCredentials("invalid credentials")
            }
        
            if jsonString.contains("UserNotConfirmedException") {
                throw AuthError.userNotConfirmed
            }
            
            guard let stringData = jsonString.data(using: .utf8),
                  let parsedString = try JSONSerialization.jsonObject(with: stringData, options: [.allowFragments]) as? String,
                  let jsonData = parsedString.data(using: .utf8),
                  let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                  let finalJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
                await MainActor.run { isLoading = false }
                throw AuthError.invalidResponse
            }
            
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: finalJsonData)
            
            await MainActor.run {
                isLoading = false
                switch httpResponse.statusCode {
                case 200:
                    if let token = loginResponse.idToken {
                        idToken = token
                        authToken = token
                        tokenExpiration = Date().timeIntervalSince1970 + tokenLifetime
                        saveTokenToKeychain(token)
                        isAuthenticated = true
                    }
                case 400:
                    errorMessage = loginResponse.message
                default:
                    errorMessage = "Unexpected response: \(httpResponse.statusCode)"
                }
            }
            
            return loginResponse
        }
    
    // MARK: - Logout
    func logout() {
            authToken = nil
            tokenExpiration = nil
            currentUser = nil
            idToken = nil
            errorMessage = nil
            isAuthenticated = false
            deleteTokenFromKeychain()
        }
    
    // Helper to delete token from Keychain
        private func deleteTokenFromKeychain() {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: "authToken"
            ] as [String: Any]
            
            SecItemDelete(query as CFDictionary)
        }
    
    // MARK: - Get Current User
    func getCurrentUser() async throws -> Profile {
            guard let token = authToken ?? idToken else {
                throw AuthError.tokenNotFound
            }
            let decodedToken = try decode(jwt: token)
            guard let sub = decodedToken["sub"].string else {
                throw AuthError.invalidResponse
            }
            
            let url = try makeURL(endpoint: "/users/\(sub)")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if isDev {
                request.cachePolicy = .reloadRevalidatingCacheData
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw AuthError.invalidResponse
            }
            
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw AuthError.invalidResponse
            }
        
            
            guard let stringData = jsonString.data(using: .utf8),
                  let parsedString = try JSONSerialization.jsonObject(with: stringData, options: [.allowFragments]) as? String,
                  let jsonData = parsedString.data(using: .utf8),
                  let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                  let finalJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
                throw AuthError.invalidResponse
            }
        
        do {
            let user1 = try JSONDecoder().decode(Profile1.self, from: finalJsonData)
            
            let user = Profile(userId: user1.userId, username: user1.username, email: user1.email, role: user1.role, status: user1.status, firstName: user1.firstName, lastName: user1.lastName, phoneNumber: user1.phoneNumber, profilePictureURL: user1.profilePictureURL, notifications: user1.notifications, favoriteListings: user1.favoriteListings)
           
            await MainActor.run {
                currentUser = user
            }
            return user
        } catch {
            print("Decoding error: \(error)")
            throw AuthError.userNotFound("User not found")
        }

        }
    
    // MARK: - Resend Verification Code
    func resendCode(username: String) async throws -> String {
        let url = try makeURL(endpoint: "/users/resend-code")
        return try await performRequest(url: url, method: "POST", body: ["username": username])
    }
    
    // MARK: - Verify Email
    func verifyEmail(verification: Verification) async throws -> String {
        let url = try makeURL(endpoint: "/users/verify-email")
        return try await performRequest(url: url, method: "POST", body: verification)
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async throws -> String {
        let url = try makeURL(endpoint: "/users/reset-password")
        return try await performRequest(url: url, method: "POST", body: ["email": email])
    }
    
    // MARK: - Confirm Reset Password
    func confirmResetPassword(email: String, code: String, password: String) async throws -> String {
        let url = try makeURL(endpoint: "/users/confirm-reset-password")
        let body = ["email": email, "code": code, "password": password]
        return try await performRequest(url: url, method: "POST", body: body)
    }
    
    // MARK: - Update User Profile
    func updateUserProfile(_ updatedProfile: Profile) async throws -> String {
        do{
            let url = try makeURL(endpoint: "/users/\(updatedProfile.userId)")
           let res =  try await performRequest(url: url, method: "PUT", body: updatedProfile)
            print("res \(res)")
            return res
        }
        catch{
            throw error
        }
    }
    
    // MARK: - Helpers
    private func makeURL(endpoint: String) throws -> URL {
        guard let url = URL(string: "\(apiBaseURL)\(endpoint)") else {
            throw AuthError.invalidURL
        }
        return url
    }
    
    private func performRequest(url: URL, method: String, body: Encodable) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw AuthError.encodingFailed(error)
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let response = String(data: data, encoding: .utf8) else {
            throw AuthError.invalidResponse
        }
        
        if response.contains("UserNotFoundException") {
            throw AuthError.userNotFound(response)
        }
        
        return response
    }
    
        private func saveTokenToKeychain(_ token: String) {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: "authToken",
                kSecValueData: token.data(using: .utf8)!,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
            ] as [String: Any]
            
            SecItemDelete(query as CFDictionary)
            SecItemAdd(query as CFDictionary, nil)
            
            // Store expiration separately in Keychain if needed
            if let expiration = tokenExpiration {
                let expirationQuery = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: "tokenExpiration",
                    kSecValueData: String(expiration).data(using: .utf8)!
                ] as [String: Any]
                
                SecItemDelete(expirationQuery as CFDictionary)
                SecItemAdd(expirationQuery as CFDictionary, nil)
            }
        }
}


struct TestGetUserView: View {
    @StateObject private var authManager = AuthManager()
    @State private var user: Profile?
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Loading...")
            }
            
            if let user = user {
                VStack(alignment: .leading, spacing: 10) {
                    Text("User Details:")
                        .font(.headline)
                    Text("Name: \(user.firstName) \(user.lastName)")
                    Text("Email: \(user.email)")
                    Text("Username: \(user.id)")
                    Text("Phone: \(user.phoneNumber)")
                    Text("Role: \(user.role )")
                    Text("Status: \(user.status)")
                }
                .padding()
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: fetchUser) {
                Text("Get Current User")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func fetchUser() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let fetchedUser = try await authManager.getCurrentUser()
                await MainActor.run {
                    user = fetchedUser
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    TestGetUserView()
}
