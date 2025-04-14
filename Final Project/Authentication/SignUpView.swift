//
//  SignUpView.swift
//
//  Created by Emmanuel Makoye on 3/1/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var firstName = FieldModel(fieldType: .firstName)
    @State private var lastName = FieldModel(fieldType: .lastName)
    @State private var email = FieldModel(fieldType: .email)
    @State private var phoneNumber = FieldModel(fieldType: .phoneNumber)
    @State private var password = FieldModel(fieldType: .password)
    @State private var username = FieldModel(fieldType: .username)
    @State private var selectedRole: UserRole = UserRole.tenant
    @State private var isShowingVerifyEmail = false
    @Environment(\.dismiss) private var dismiss
    
    private let roles: [UserRole] = [.tenant, .landlord]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        CustomTextField(fieldModel: $firstName)
                        CustomTextField(fieldModel: $lastName)
                        CustomTextField(fieldModel: $email)
                        CustomTextField(fieldModel: $phoneNumber)
                        CustomSecureField(fieldModel: $password)
                        CustomTextField(fieldModel: $username)
                    }
                    
                    CustomButton(title: "Sign Up") {
                        submitForm()
                    }
                    
                    if let error = authManager.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        NavigationLink("Sign In") {
                            LoginView()
                                .environmentObject(authManager)
                                .navigationBarBackButtonHidden(true)
                        }
                        .foregroundColor(.blue)
                    }
                    .font(.subheadline)
                    .padding(.vertical, 20)
                    
                    Spacer()
                }
                .background(Color(.systemBackground))
                .navigationTitle("Sign Up")
                .navigationDestination(isPresented: $isShowingVerifyEmail) {
                    VerifyEmailView(email: email.value, username: username.value)
                        .environmentObject(authManager)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        var isValid = true
        isValid = firstName.onValidate() && isValid
        isValid = lastName.onValidate() && isValid
        isValid = email.onValidate() && isValid
        isValid = phoneNumber.onValidate() && isValid
        isValid = password.onValidate() && isValid
        isValid = username.onValidate() && isValid
        return isValid
    }
    
    private func submitForm() {
        guard isFormValid else {
            firstName.onSubmitError()
            lastName.onSubmitError()
            email.onSubmitError()
            phoneNumber.onSubmitError()
            password.onSubmitError()
            username.onSubmitError()
            return
        }
        
        Task {
            do {
                let formattedPhoneNumber = phoneNumber.value.hasPrefix("+1") ? phoneNumber.value : "+1" + phoneNumber.value

                let user = User(
                    id: UUID().uuidString,
                    userId: UUID().uuidString,
                    username: username.value,
                    email: email.value,
                    password: password.value,
                    role: selectedRole,
                    phoneNumber: formattedPhoneNumber
                )
                let response = try await authManager.signup(user)
                isShowingVerifyEmail = true
                print("Signup response: \(response)")
                let profile = Profile(
                    userId: response.userId,
                    username: user.username,
                    email: user.email,
                    role: user.role,
                    status: "unverified",
                    firstName: firstName.value,
                    lastName: lastName.value,
                    phoneNumber: phoneNumber.value,
                    profilePictureURL: ""
                )
                
                let res = try await authManager.updateUserProfile(profile)
            }
            catch AuthError.usernameExists {
                // Handle username already exists error
                authManager.errorMessage = "user already exists"
            }
            catch {
                authManager.errorMessage = error.localizedDescription
                // Handle any other errors
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func resendVerificationCode() async {
        do {
            // Attempt to resend the verification code
            let response = try await authManager.resendCode(username: username.value)
            isShowingVerifyEmail = true
            print("Verification code resent successfully: \(response)")
        } catch {
            print("Failed to resend verification code: \(error.localizedDescription)")
        }
    }

}



#Preview("Light Mode") {
    SignUpView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    SignUpView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.dark)
}
