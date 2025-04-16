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
import SwiftData

// MARK: - Auth Manager
class AuthManager: ObservableObject {
    @AppStorage("authToken") private var authToken: String?
    @AppStorage("tokenExpiration") private var tokenExpiration: Double?
    @AppStorage("lastUsedGuestId") private var lastUsedGuestId: String?
    private let apiBaseURL = "https://4wpft6a3qc.execute-api.us-east-2.amazonaws.com/dev/"
    
    private let isDev = ProcessInfo.processInfo.environment["NODE_ENV"] == "development"
    private let tokenLifetime: TimeInterval = 7 * 24 * 60 * 60
    
    @Published var errorMessage: String?
    @Published var idToken: String?
    @Published var isLoading: Bool = false
    @Published var currentUser: Profile?
    @Published var isAuthenticated: Bool = false
    @Published var userSwiftDataModel: UserData?
    
    // Model context for SwiftData
    private var modelContext: ModelContext?
    
    init() {
        checkTokenValidity()
    }
    
    // Set model context from view
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
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
    
    // MARK: - Guest User Handling with SwiftData
    
    // Create and persist guest user
    func createGuestUser() {
        let guestId = UUID().uuidString
        let username = "Guest\(Int.random(in: 1000...9999))"
        let email = "guest+\(Int.random(in: 1000...9999))@stoky.com"
        
        // Create Profile for current session
        let guestUser = Profile(
            userId: guestId,
            username: username,
            email: email,
            role: UserRole.guest,
            status: "active",
            firstName: "Guest",
            lastName: "User",
            phoneNumber: "000-000-\(Int.random(in: 1000...9999))",
            profilePictureURL: ""
        )
        
        // Create SwiftData model for persistence
        let userData = UserData(
            userId: guestId,
            username: username,
            email: email,
            role: UserRole.guest.rawValue,
            status: "active",
            firstName: "Guest",
            lastName: "User",
            phoneNumber: "000-000-\(Int.random(in: 1000...9999))",
            profilePictureURL: "",
            accountBalance: 1000.0  // Default starting balance
        )
        
        // Save to SwiftData
        if let context = modelContext {
            context.insert(userData)
            do {
                try context.save()
                print("Guest user saved to SwiftData: \(userData.username)")
                
                // Store the user ID for later retrieval
                lastUsedGuestId = guestId
                
                // Set the current user for the session
                self.currentUser = guestUser
                self.userSwiftDataModel = userData
            } catch {
                print("Failed to save guest user: \(error)")
                // Fallback - still set the current user for the session
                self.currentUser = guestUser
            }
        } else {
            print("ModelContext not set - user will not persist")
            // Still set the user for the current session
            self.currentUser = guestUser
        }
    }
    
    // Try to restore the last guest user
    func restoreLastGuestUser() -> Bool {
        guard let context = modelContext, let guestId = lastUsedGuestId else {
            return false
        }
        
        do {
            let descriptor = FetchDescriptor<UserData>(
                predicate: #Predicate<UserData> { user in
                    user.userId == guestId
                }
            )
            
            let users = try context.fetch(descriptor)
            
            if let userData = users.first {
                print("Found previous guest user: \(userData.username)")
                
                // Create Profile for current session
                let profile = Profile(
                    userId: userData.userId,
                    username: userData.username,
                    email: userData.email,
                    role: UserRole(rawValue: userData.role) ?? .guest,
                    status: userData.status,
                    firstName: userData.firstName,
                    lastName: userData.lastName,
                    phoneNumber: userData.phoneNumber,
                    profilePictureURL: userData.profilePictureURL
                )
                
                self.currentUser = profile
                self.userSwiftDataModel = userData
                return true
            }
        } catch {
            print("Error fetching previous guest user: \(error)")
        }
        
        return false
    }
    
    // Update user's account balance and record transaction
    func updateAccountBalance(amount: Double, transactionType: TransactionType? = nil, ticker: String? = nil, quantity: Int? = nil, pricePerShare: Double? = nil) -> Double? {
        guard let userData = userSwiftDataModel, let context = modelContext else {
            return nil
        }
        
        let oldBalance = userData.accountBalance
        userData.accountBalance = amount
        
        // Record transaction if specified
        if let transactionType = transactionType {
            let userId = userData.userId
            
            // Calculate proper transaction amount
            let transactionAmount: Double
            switch transactionType {
            case .deposit:
                transactionAmount = amount - oldBalance // Amount added
            case .buy:
                transactionAmount = -(pricePerShare ?? 0) * Double(quantity ?? 0) // Negative for purchase
            case .sell:
                transactionAmount = (pricePerShare ?? 0) * Double(quantity ?? 0) // Positive for sale
            }
            
            let transaction = TransactionData(
                id: UUID().uuidString, // Ensure a new UUID each time
                userId: userId,
                type: transactionType,
                amount: transactionAmount,
                ticker: ticker,
                quantity: quantity,
                pricePerShare: pricePerShare,
                timestamp: Date() // Ensure current date
            )
            
            print("Creating transaction: \(transaction.description) for user \(userId)")
            
            // Insert transaction manually - important to ensure it's tracked by SwiftData
            context.insert(transaction)
            
            // Try to save immediately
            do {
                try context.save()
                print("Transaction saved successfully")
            } catch {
                print("Error saving transaction: \(error)")
            }
        }
        
        // Save user data changes
        do {
            try context.save()
            print("Saved user data and updated balance to: \(amount)")
            return userData.accountBalance
        } catch {
            print("Failed to update account balance: \(error)")
            return nil
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
        // Check if current user is a guest and delete their data
        if let userData = userSwiftDataModel,
           let context = modelContext,
           let user = currentUser,
           user.role == .guest {
            
            // Delete all user's transactions
            let userId = userData.userId
            let transactionDescriptor = FetchDescriptor<TransactionData>(
                predicate: #Predicate<TransactionData> { transaction in
                    transaction.userId == userId
                }
            )
            
            do {
                let userTransactions = try context.fetch(transactionDescriptor)
                for transaction in userTransactions {
                    context.delete(transaction)
                }
                
                // Delete all user's stocks
                let stockDescriptor = FetchDescriptor<StockItem>()
                let allStocks = try context.fetch(stockDescriptor)
                for stock in allStocks {
                    context.delete(stock)
                }
                
                // Delete the user data
                context.delete(userData)
                try context.save()
                
                // Remove reference to last guest ID
                UserDefaults.standard.removeObject(forKey: "lastUsedGuestId")
                
            } catch {
                print("Error deleting guest data: \(error)")
            }
        }
        
        // Standard logout actions
        authToken = nil
        tokenExpiration = nil
        currentUser = nil
        idToken = nil
        errorMessage = nil
        isAuthenticated = false
        userSwiftDataModel = nil
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
