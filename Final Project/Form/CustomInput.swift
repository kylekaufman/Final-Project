//
//  CustomInput.swift
//
//  Created by Emmanuel Makoye on 3/1/25.
//

import SwiftUI

struct CustomTextField: View {
    var fieldModel: Binding<FieldModel>
    @Environment(\.colorScheme) var colorScheme
    
    private var borderColor: Color {
        colorScheme == .dark ? .white.opacity(0.3) : .gray.opacity(0.5)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray.opacity(0.15) : .gray.opacity(0.05)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(fieldModel.wrappedValue.fieldType.placeHolder)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            // Input Field
            TextField("", text: fieldModel.value)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(fieldModel.wrappedValue.error != nil ? .red : borderColor, lineWidth: 1)
                )
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
                .keyboardType(.default)
                .textCase(nil)
                .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.2), value: fieldModel.wrappedValue.error)
            
            // Error Message
            if let error = fieldModel.wrappedValue.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)    
    }
}

struct CustomSecureField: View {
    var fieldModel: Binding<FieldModel>
    @State private var isSecure: Bool = true
    @Environment(\.colorScheme) var colorScheme
    
    private var borderColor: Color {
        colorScheme == .dark ? .white.opacity(0.3) : .gray.opacity(0.5)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray.opacity(0.15) : .gray.opacity(0.05)
    }
    
    private var toggleColor: Color {
        colorScheme == .dark ? .white : .blue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(fieldModel.wrappedValue.fieldType.placeHolder)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            // Input Field with Toggle
            HStack {
                if isSecure {
                    SecureField("", text: fieldModel.value)
                        .textContentType(.password)
                } else {
                    TextField("", text: fieldModel.value)
                        .textContentType(.password)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(fieldModel.wrappedValue.error != nil ? .red : borderColor, lineWidth: 1)
            )
            .autocapitalization(.none)
            .autocorrectionDisabled(true)
            .keyboardType(.default)
            .overlay(
                Button(action: { withAnimation { isSecure.toggle() } }) {
                    Text(isSecure ? "Show" : "Hide")
                        .font(.caption)
                        .foregroundColor(toggleColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(toggleColor.opacity(0.1))
                        .cornerRadius(6)
                }
                .padding(.trailing, 8),
                alignment: .trailing
            )
            .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .gray.opacity(0.1), radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.2), value: fieldModel.wrappedValue.error)
            
            // Error Message
            if let error = fieldModel.wrappedValue.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct CustomButton: View {
    var title: String
    var action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.purple)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .gray.opacity(0.3), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorScheme == .dark ? .white.opacity(0.2) : .gray.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// Example Usage for Preview
struct FormViews: View {
    @State private var email = FieldModel(fieldType: .email)
    @State private var password = FieldModel(fieldType: .password)
    
    var body: some View {
        VStack(spacing: 0) { // No extra spacing here, controlled by components
            CustomTextField(fieldModel: $email)
            CustomSecureField(fieldModel: $password)
            CustomButton(title: "Submit") {
                print("Button tapped")
            }
        }
        .background(Color(.systemBackground))
    }
}

#Preview("Light Mode") {
    FormViews()
        .environmentObject(AuthManager())
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    FormViews()
        .environmentObject(AuthManager())
        .preferredColorScheme(.dark)
}
