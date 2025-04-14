//
//  Models.swift
//  Final Project
//
//  Created by Emmanuel Makoye on 4/6/25.
//


import Foundation
import SwiftUI
import JWTDecode
import Security

// MARK: - User-Related Models

/// Defines user roles in the rental app
enum UserRole: String, Codable {
    case landlord
    case tenant
    case guest
}

/// Represents a user with basic identifying information
struct User: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let email: String
    let password: String
    let role: UserRole
    let phoneNumber: String
}

struct Profile1: Codable{
    let userId: String
    let username: String
    let email: String
    let role: UserRole
    let status: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let profilePictureURL: String?
    let notifications: [Notification]
    let favoriteListings: [String]?
}

/// Detailed user object from authentication service
struct Profile: Codable, Identifiable {
    var id: String
    let userId: String
    let username: String
    let email: String
    let role: UserRole
    let status: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let profilePictureURL: String?
    let notifications: [Notification]
    let favoriteListings: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case username
        case email
        case role
        case status
        case firstName
        case lastName
        case phoneNumber
        case profilePictureURL
        case notifications  // Added
        case favoriteListings  // Added
    }

    init(
        userId: String,
        username: String,
        email: String,
        role: UserRole,
        status: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        profilePictureURL: String? = nil,
        notifications: [Notification] = [],  // Default to empty array
        favoriteListings: [String]? = nil
    ) {
        self.userId = userId
        self.username = username
        self.email = email
        self.role = role
        self.status = status
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.profilePictureURL = profilePictureURL
        self.notifications = notifications
        self.favoriteListings = favoriteListings
        self.id = userId
    }
}

/// Represents a rental listing
struct Listing: Identifiable, Codable {
    let listingId: String? // Nil for new listings, filled when fetched from DynamoDB
    var id: UUID { UUID(uuidString: listingId ?? UUID().uuidString) ?? UUID() } // Ensures Identifiable
    let ownerId: String
    let title: String
    let location: String
    let price: Double
    let images: [String]
    let hasParking: Bool
    let hasKitchen: Bool
    let propertyType: String
    let bedrooms: Int
    let bathrooms: Int
    let isFurnished: Bool
    let distance: Double?
    var reviews: [Review] = []
}

// MARK: - Listing-Related Models
/// Represents a review for a listing, including rating and optional media
struct Review: Identifiable, Codable {
    let reviewId: String
    var id: UUID
    var content: String
    var rating: Int
    var timestamp: Date
    var userId: String
    var mediaURLs: [String]
    
    /// Creates a review with default timestamp and optional media
    init(content: String, rating: Int, timestamp: Date = Date(), mediaURLs: [String] = [], userId: String, reviewId: String){
        self.id = UUID(uuidString: reviewId) ?? UUID()
        self.userId = userId
        self.content = content
        self.rating = rating
        self.timestamp = timestamp
        self.mediaURLs = mediaURLs
        self.reviewId = reviewId
    }
    
    /// Ensures rating is within valid range (1-5)
    mutating func setRating(_ rating: Int) {
        self.rating = max(1, min(5, rating))
    }
    /// sets review contents
    mutating func setContent(_ content: String) {
        self.content = content
    }
}

// MARK: - Notification Model

/// Represents a notification sent by a landlord to tenants or all users
struct Notification: Identifiable, Codable {
    let id: UUID = UUID()
    let senderID: UUID // Landlord who sent the notification
    let title: String
    let content: String
    var timestamp: String
    let recipientIDs: [UUID]? // Specific tenant IDs or nil for broadcast
    var isRead: Bool
    
    // MARK: - Initialization
    
    /// Creates a notification with the given details
    init(senderID: UUID, title: String, content: String, timestamp: String, recipientIDs: [UUID]? = nil, isRead: Bool = false) {
        self.senderID = senderID
        self.title = title
        self.content = content
        self.timestamp = timestamp
        self.recipientIDs = recipientIDs
        self.isRead = isRead
        self.timestamp = timestamp
    }
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, senderID, title, content, timestamp, recipientIDs, isRead
    }
}

// MARK: - Authentication-Related Models

/// Data for user sign-in
struct SignInFormData: Codable {
    let username: String
    let password: String
}

/// Data for email verification
struct Verification: Codable {
    let username: String
    let verificationCode: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case verificationCode = "verification_code"
    }
}

/// Response from login API
struct LoginResponse: Codable {
    let message: String
    let idToken: String?
}

struct SignUpResponse: Codable{
    let message: String
    let userId: String
}

// MARK: - Helper Models for Authentication

/// Authentication-specific errors
enum AuthError: Error, LocalizedError {
    case invalidURL
    case encodingFailed(Error)
    case networkError(Error)
    case invalidResponse
    case userNotFound(String)
    case verificationFailed(String)
    case tokenNotFound
    case usernameExists
    case invalidCredentials(String)
    case signInFailed(String)
    case userNotConfirmed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .encodingFailed(let error): return "Encoding failed: \(error.localizedDescription)"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .invalidResponse: return "Invalid response from server"
        case .userNotFound(let message): return "User not found: \(message)"
        case .verificationFailed(let message): return "Verification failed: \(message)"
        case .tokenNotFound: return "Authentication token not found"
        case .usernameExists: return "Username already exists"
        case .invalidCredentials(let message): return "Invalid credentials: \(message)"
        case .signInFailed(let message): return "Sign-in failed: \(message)"
        case .userNotConfirmed: return "User's email not confirmed"
        }
    }
}
