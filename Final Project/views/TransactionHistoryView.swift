//
//  TransactionHistoryView.swift
//  Final Project
//
//  Created by Mufu Tebit on 4/15/25.
//


import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthManager
    
    // Query for transactions, sorted by date (newest first)
    @Query private var allTransactions: [TransactionData]
    
    init() {
        // Create a sort descriptor for the timestamp
        let sortDescriptor = SortDescriptor<TransactionData>(\.timestamp, order: .reverse)
        
        // Create a query with the sort descriptor
        let descriptor = FetchDescriptor<TransactionData>(sortBy: [sortDescriptor])
        _allTransactions = Query(descriptor)
        
        // Debug output
        print("TransactionHistoryView initialized with new descriptor")
    }
    
    // Filter for current user's transactions
    private var userTransactions: [TransactionData] {
        guard let userData = authManager.userSwiftDataModel else { return [] }
        let userId = userData.userId
        
        let filtered = allTransactions.filter { $0.userId == userId }
        print("Filtering transactions for user \(userId): \(filtered.count) found")
        return filtered
    }
    
    var body: some View {
        NavigationView {
            List {
                if userTransactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Your transaction history will appear here")
                    )
                } else {
                    ForEach(userTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
            .navigationTitle("Transaction History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                print("Transaction view appeared - found \(userTransactions.count) transactions")
                userTransactions.forEach { transaction in
                    print("Transaction: \(transaction.description) - \(transaction.timestamp)")
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: TransactionData
    
    private var typeIcon: String {
        switch TransactionType(rawValue: transaction.type) {
        case .deposit:
            return "arrow.down.circle.fill"
        case .buy:
            return "cart.fill"
        case .sell:
            return "dollarsign.circle.fill"
        case nil:
            return "questionmark.circle.fill"
        }
    }
    
    private var typeColor: Color {
        switch TransactionType(rawValue: transaction.type) {
        case .deposit:
            return .green
        case .buy:
            return .red
        case .sell:
            return .green
        case nil:
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: typeIcon)
                .font(.title2)
                .foregroundColor(typeColor)
                .frame(width: 32, height: 32)
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.body)
                    .lineLimit(1)
                
                HStack {
                    Text(transaction.timestamp, style: .date)
                    Text("•")
                    Text(transaction.timestamp, style: .time)
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Amount
            Text(amountText)
                .fontWeight(.semibold)
                .foregroundColor(typeColor)
        }
        .padding(.vertical, 8)
    }
    
    private var amountText: String {
        let prefix = transaction.amount >= 0 ? "+" : ""
        return "\(prefix)$\(String(format: "%.2f", transaction.amount))"
    }
}

#Preview {
    TransactionHistoryView()
        .environmentObject(AuthManager())
        .modelContainer(for: [TransactionData.self])
}
