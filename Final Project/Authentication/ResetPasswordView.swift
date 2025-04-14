//
//  ResetPasswordView.swift
//
//  Created by Emmanuel Makoye on 3/1/25.
//

import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var email = FieldModel(fieldType: .email)
    @State private var code = FieldModel(value: "", fieldType: .code)
    @State private var newPassword = FieldModel(fieldType: .password)
    @State private var confirmNewPassword = FieldModel(fieldType: .password)
    @State private var isCodeSent = false
    @State private var successMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title
                Text(isCodeSent ? "Reset Your Password" : "Forgot Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                if !isCodeSent {
                    // Form Fields
                    CustomTextField(fieldModel: $email)
                }
               
                
                if isCodeSent {
                    CustomTextField(fieldModel: $code)
                        .keyboardType(.numberPad) // Code is typically numeric
                    CustomSecureField(fieldModel: $newPassword)
                    CustomSecureField(fieldModel: $confirmNewPassword)
                }
                
                // Submit Button
                CustomButton(title: isCodeSent ? "Confirm Reset" : "Send Reset Code") {
                    isCodeSent ? confirmReset() : sendResetCode()
                }
                
                // Messages
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                
                if let success = successMessage {
                    Text(success)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                // Cancel Button
                Button("Cancel") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
    
    // Form Validation
    private var isFormValid: Bool {
        if isCodeSent {
            return email.onValidate() && code.onValidate() && newPassword.onValidate()
        } else {
            return email.onValidate()
        }
    }
    
    // Send Reset Code
    private func sendResetCode() {
        guard email.onValidate() else {
            email.onSubmitError()
            return
        }
        
        Task {
            do {
                let response = try await authManager.resetPassword(email: email.value)
                print("Reset code sent: \(response)")
                successMessage = "A reset code has been sent to your email."
                isCodeSent = true
                authManager.errorMessage = nil
            } catch {
                authManager.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Confirm Reset
    private func confirmReset() {
        guard isFormValid else {
            email.onSubmitError()
            code.onSubmitError()
            newPassword.onSubmitError()
            return
        }
        
        Task {
            do {
                let response = try await authManager.confirmResetPassword(
                    email: email.value,
                    code: code.value,
                    password: newPassword.value
                )
                print("Password reset confirmed: \(response)")
                successMessage = "Password reset successfully! You can now log in."
                authManager.errorMessage = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss() // Auto-dismiss after success
                }
            } catch {
                authManager.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview("Light Mode - Initial") {
    ResetPasswordView()
        .preferredColorScheme(.light)
        .environmentObject(AuthManager())
}

#Preview("Dark Mode - Confirmation") {
    ResetPasswordView()
        .preferredColorScheme(.dark)
        .environmentObject(AuthManager())
}
