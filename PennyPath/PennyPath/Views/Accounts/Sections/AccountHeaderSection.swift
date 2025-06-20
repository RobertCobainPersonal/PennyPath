//
//  AccountHeaderSection.swift
//  PennyPath
//
//  Created by Robert Cobain on 20/06/2025.
//


import SwiftUI

/// Reusable account header displaying balance and basic account information
/// Used in AccountDetailView and can be reused in account summary cards, dashboard widgets, etc.
struct AccountHeaderSection: View {
    let account: Account?
    
    var body: some View {
        CardView {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(account?.name ?? "Account")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(account?.type.displayName ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(account?.balance.formattedAsCurrency ?? "")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(balanceColor)
                        
                        Text("Current Balance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var balanceColor: Color {
        guard let balance = account?.balance else { return .primary }
        
        switch account?.type {
        case .credit:
            return balance < 0 ? .red : .green
        case .loan:
            return .orange
        default:
            return balance >= 0 ? .primary : .red
        }
    }
}

// MARK: - Preview Provider
struct AccountHeaderSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Current Account
            AccountHeaderSection(
                account: Account(
                    userId: "test",
                    name: "Barclays Current Account",
                    type: .current,
                    balance: 2485.67
                )
            )
            
            // Credit Card
            AccountHeaderSection(
                account: Account(
                    userId: "test",
                    name: "AMEX Gold Card",
                    type: .credit,
                    balance: -847.23,
                    creditLimit: 5000.0
                )
            )
            
            // Loan Account
            AccountHeaderSection(
                account: Account(
                    userId: "test",
                    name: "Car Finance",
                    type: .loan,
                    balance: -8500.00,
                    originalLoanAmount: 15000.0
                )
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Account Headers")
    }
}