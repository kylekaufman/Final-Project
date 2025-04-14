//
//  VerifyEmailView.swift
//
//  Created by Emmanuel Makoye on 3/1/25.
//


import SwiftUI

struct VerifyEmailView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var email: String // Email passed from SignUpView
    @State private var username: String // username passed from SignUpView
    @State private var code = FieldModel(value: "", fieldType: .code) // Using resetCode for simplicity
    @State private var successMessage: String?
    
    init(email: String, username: String) {
        self._email = State(initialValue: email)
        self._username = State(initialValue: username)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title
                Text("Verify Your Email")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                
                // Instruction
                Text("A verification code has been sent to \(email). Please enter it below.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                
                // Code Field
                CustomTextField(fieldModel: $code)
                    .keyboardType(.numberPad) // Assuming code is numeric
                
                // Verify Button
                CustomButton(title: "Verify Email") {
                    verifyEmail()
                }
                
                // Resend Code Button
                Button("Resend Code") {
                    resendCode()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.top, 8)
                
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
            .navigationTitle("Verify Your Email")
        }
    }
    
    // Form Validation
    private var isFormValid: Bool {
        return code.onValidate()
    }
    
    // Verify Email
    private func verifyEmail() {
        guard isFormValid else {
            code.onSubmitError()
            return
        }
        
        Task {
            do {
                let verification = Verification(username: username, verificationCode: code.value)
                let response = try await authManager.verifyEmail(verification: verification)
                print("Email verification response: \(response)")
                successMessage = "Email verified successfully! You can now log in."
                authManager.errorMessage = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss() // Auto-dismiss after success
                }
            } catch {
                authManager.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Resend Code
    private func resendCode() {
        Task {
            do {
                let response = try await authManager.resendCode(username: email)
                print("Resend code response: \(response)")
                successMessage = "A new verification code has been sent to your email."
                authManager.errorMessage = nil
            } catch {
                authManager.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview
#Preview("Light Mode") {
    VerifyEmailView(email: "test@example.com", username: "mak")
        .preferredColorScheme(.light)
        .environmentObject(AuthManager())
}

#Preview("Dark Mode") {
    VerifyEmailView(email: "test@example.com", username: "mak")
        .preferredColorScheme(.dark)
        .environmentObject(AuthManager())
}
