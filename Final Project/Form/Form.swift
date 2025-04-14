//
//  Form.swift
//  RentalApp
//
//  Created by Emmanuel Makoye on 3/1/25.
//


import Foundation

protocol FieldValidatorProtocol {
    func validate(value: String) -> String?
}

enum FieldType: FieldValidatorProtocol {
    case email
    case password
    case username
    case phoneNumber
    case confirmPassword
    case firstName
    case lastName
    case city
    case role
    case code
    
    var placeHolder: String {
        switch self {
        case .email:
            return "Email"
        case .password:
            return "Password"
        case .username:
            return "Username"
        case .phoneNumber:
            return "Phone Number"
        case .confirmPassword:
            return "Confirm Password"
        case .firstName:
            return "First Name"
        case .lastName:
            return "Last Name"
        case .city:
            return "City"
        case .role:
            return "Role"
        case .code:
            return "Code"
        }
    }
    
    func validate(value: String) -> String? {
        switch self {
        case .email:
            return emailValidate(value: value)
        case .password:
            return passwordValidate(value: value)
        case .username:
            return usernameValidate(value: value)
        case .phoneNumber:
            return phoneNumberValidate(value: value)
        case .confirmPassword:
            return confirmPasswordValidate(value: value)
        case .firstName:
            return nameValidate(value: value, field: "First Name")
        case .lastName:
            return nameValidate(value: value, field: "Last Name")
        case .city:
            return cityValidate(value: value)
        case .role:
            return roleValidate(value: value)
        case .code:
            return nameValidate(value: value, field: "Code")
        }

    }
    
    private func emailValidate(value: String) -> String? {
        if value.isEmpty {
            return "Please enter your email"
        } else {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            return emailPred.evaluate(with: value) ? nil : "Please enter your valid email"
        }
    }
    
    private func passwordValidate(value: String) -> String? {
        if value.isEmpty {
            return "Please enter your password"
        } else if value.count < 8 {
            return "Password must be at least 8 characters long"
        }
        return nil
    }
    
    private func usernameValidate(value: String) -> String? {
        if value.isEmpty {
            return "Please enter your username"
        } else if value.count < 3 {
            return "Username must be at least 3 characters long"
        } else if value.rangeOfCharacter(from: .whitespaces) != nil {
            return "Username cannot contain spaces"
        }
        return nil
    }
    
    private func phoneNumberValidate(value: String) -> String? {
        if value.isEmpty {
            return "Please enter your phone number"
        } else {
            let phoneRegex = "^\\+?\\d{10,14}$" // Accepts + and 10-14 digits (e.g., +1234567890)
            let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            return phonePred.evaluate(with: value) ? nil : "Please enter a valid phone number"
        }
    }
    
    private func confirmPasswordValidate(value: String) -> String? {
        // In a real app, you'd compare with passwordField.value from ViewModel
        return value.isEmpty ? "Please confirm your password" : nil
        // Note: To properly validate against the actual password, you'd need to pass the password value or use a ViewModel reference
    }
    
    private func nameValidate(value: String, field: String) -> String? {
        if value.isEmpty {
            return "Please enter your \(field)"
        } else if value.count < 2 {
            return "\(field) must be at least 2 characters long"
        }
        return nil
    }
    
    private func cityValidate(value: String) -> String? {
        if value.isEmpty {
            return "Please enter your city"
        }
        return nil
    }
    
    private func roleValidate(value: String) -> String? {
        if value.isEmpty {
            return "Please select a role"
        } else if !["user", "admin", "moderator"].contains(value.lowercased()) {
            return "Invalid role selected"
        }
        return nil
    }
}

struct FieldModel: Identifiable {
    var id = UUID()
    var value: String
    var error: String?
    var fieldType: FieldType
    
    init(value: String = "", fieldType: FieldType, error: String? = nil) {
        self.value = value
        self.fieldType = fieldType
        self.error = error
    }
    
    mutating func onValidate() -> Bool {
        error = fieldType.validate(value: value)
        return error == nil
    }
    
    mutating func onSubmitError() {
        error = fieldType.validate(value: value)
    }
}
