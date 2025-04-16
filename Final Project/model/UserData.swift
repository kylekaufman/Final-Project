//
//  UserData.swift
//  Final Project
//
//  Created by Mufu Tebit on 4/15/25.
//


import Foundation
import SwiftData

@Model
class UserData {
    @Attribute(.unique) var userId: String
    var username: String
    var email: String
    var role: String
    var status: String
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var profilePictureURL: String?
    var accountBalance: Double
    
    init(userId: String, 
         username: String, 
         email: String, 
         role: String, 
         status: String, 
         firstName: String, 
         lastName: String, 
         phoneNumber: String, 
         profilePictureURL: String? = nil,
         accountBalance: Double = 1000.0) {
        self.userId = userId
        self.username = username
        self.email = email
        self.role = role
        self.status = status
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.profilePictureURL = profilePictureURL
        self.accountBalance = accountBalance
    }
}
