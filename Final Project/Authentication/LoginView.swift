//
//  LoginView.swift
//
//  Created by Emmanuel Makoye on 2/27/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var username = FieldModel(fieldType: .username)
    @State private var password = FieldModel(fieldType: .password)
    @State private var isShowingResetPassword = false
    @State private var isShowingVerifyEmail = false // New state for navigation
    @State private var emailForVerification: String? // Store email for VerifyEmailView

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Form Fields
                CustomTextField(fieldModel: $username)
                    .padding(.horizontal, 16)
                CustomSecureField(fieldModel: $password)
                    .padding(.horizontal, 16)
                
                // Forgot Password Link
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        isShowingResetPassword = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                
                // Submit Button
                CustomButton(title: "Log In", action: submitForm)
                    .padding(.horizontal, 16)
                    .opacity(authManager.isLoading ? 0.6 : 1.0)
                
                // Loading Indicator
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                // Error Message
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Sign Up Link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    NavigationLink("Sign Up", destination: SignUpView()
                        .environmentObject(authManager)
                        .navigationBarBackButtonHidden(true))
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Log In")
            .sheet(isPresented: $isShowingResetPassword) {
                ResetPasswordView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $isShowingVerifyEmail) {
                if let email = emailForVerification {
                    VerifyEmailView(email: email, username: username.value)
                        .environmentObject(authManager)
                }
            }
            .animation(.easeInOut, value: authManager.errorMessage)
        }
    }
    
    // MARK: - Form Validation
    private var isFormValid: Bool {
        username.onValidate() && password.onValidate()
    }
    
    // MARK: - Submit Form
    private func submitForm() {
        guard isFormValid else {
            username.onSubmitError()
            password.onSubmitError()
            return
        }
        
        Task {
            do {
                let signInData = SignInFormData(username: username.value, password: password.value)
                let response = try await authManager.signin(signInData)
                print("Logged in with token: \(response.idToken ?? "No token")")
                let user = try await authManager.getCurrentUser()
                print("Logged in user: \(user.firstName) \(user.lastName)")
                // No need for isNavigatingToHome; NESTApp handles the switch
            } catch AuthError.invalidCredentials(let message) {
                authManager.errorMessage = "Incorrect username or password. Please try again."
                print("Login error: \(message)")
            } catch AuthError.userNotFound(let message) {
                authManager.errorMessage = "User not found. Please sign up first."
                print("User not found: \(message)")
            } catch AuthError.invalidResponse {
                authManager.errorMessage = "Unable to process the server response. Please try again later."
            } catch AuthError.userNotConfirmed {
                // Handle unverified user
                do {
                    let response = try await authManager.resendCode(username: username.value)
                    print("Resend code response: \(response)")
                    emailForVerification = username.value
                    authManager.errorMessage = "Your email is not verified. A new code has been sent."
                    isShowingVerifyEmail = true
                } catch {
                    authManager.errorMessage = "Failed to resend verification code: \(error.localizedDescription)"
                }
            } catch {
                authManager.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                print("Unexpected error: \(error)")
            }
        }
    }
}

// MARK: - Previews
#Preview("Light Mode") {
    LoginView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LoginView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.dark)
}
