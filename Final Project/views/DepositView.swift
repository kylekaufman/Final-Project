//
//  DepositView.swift
//  Final Project
//
//  Created by Mufu Tebit on 4/15/25.
//


import SwiftUI

struct DepositView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amount: String = "0.00"
    var onDeposit: (Double) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Deposit Funds")
                .font(.title)
                .fontWeight(.bold)
            
            // Amount display
            Text("$\(amount)")
                .font(.system(size: 40, weight: .bold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            
            // Number pad
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    NumberButton(number: "1", action: { appendDigit("1") })
                    NumberButton(number: "2", action: { appendDigit("2") })
                    NumberButton(number: "3", action: { appendDigit("3") })
                }
                
                HStack(spacing: 15) {
                    NumberButton(number: "4", action: { appendDigit("4") })
                    NumberButton(number: "5", action: { appendDigit("5") })
                    NumberButton(number: "6", action: { appendDigit("6") })
                }
                
                HStack(spacing: 15) {
                    NumberButton(number: "7", action: { appendDigit("7") })
                    NumberButton(number: "8", action: { appendDigit("8") })
                    NumberButton(number: "9", action: { appendDigit("9") })
                }
                
                HStack(spacing: 15) {
                    NumberButton(number: "C", action: { clearAmount() })
                    NumberButton(number: "0", action: { appendDigit("0") })
                    NumberButton(number: "⌫", action: { deleteDigit() })
                }
            }
            .padding()
            
            // Action buttons
            HStack(spacing: 20) {
                Button("Cancel") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
                
                Button("Deposit") {
                    if let depositAmount = Double(amount) {
                        onDeposit(depositAmount)
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(depositIsValid ? Color.blue : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!depositIsValid)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // Check if deposit amount is valid
    private var depositIsValid: Bool {
        if let value = Double(amount), value > 0 {
            return true
        }
        return false
    }
    
    // Append digit to amount
    private func appendDigit(_ digit: String) {
        // Convert to numeric format without decimal
        var numericValue = amount.replacingOccurrences(of: ".", with: "")
        
        // Remove leading zeros
        while numericValue.hasPrefix("0") && numericValue.count > 2 {
            numericValue.removeFirst()
        }
        
        // Append the new digit
        numericValue.append(digit)
        
        // Convert back to decimal format (with fixed 2 decimal places)
        if numericValue.count == 1 {
            numericValue = "00" + numericValue
        } else if numericValue.count == 2 {
            numericValue = "0" + numericValue
        }
        
        // Insert decimal point
        let insertIndex = numericValue.index(numericValue.endIndex, offsetBy: -2)
        numericValue.insert(".", at: insertIndex)
        
        amount = numericValue
    }
    
    // Delete last digit
    private func deleteDigit() {
        // Convert to numeric format without decimal
        var numericValue = amount.replacingOccurrences(of: ".", with: "")
        
        // Remove last digit
        if numericValue.count > 1 {
            numericValue.removeLast()
        } else {
            numericValue = "0"
        }
        
        // Ensure we have at least 3 digits for proper decimal formatting
        while numericValue.count < 3 {
            numericValue = "0" + numericValue
        }
        
        // Insert decimal point
        let insertIndex = numericValue.index(numericValue.endIndex, offsetBy: -2)
        numericValue.insert(".", at: insertIndex)
        
        amount = numericValue
    }
    
    // Clear amount
    private func clearAmount() {
        amount = "0.00"
    }
}

// Button for number pad
struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.semibold)
                .frame(width: 70, height: 70)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DepositView(onDeposit: { _ in })
}