//
//  TransactionRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 17/06/2025.
//


//
//  TransactionRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

/// Reusable component for displaying transaction information in lists
/// Used across AccountDetail, TransactionsList, Dashboard, and search results
struct TransactionRowView: View {
    let transaction: Transaction
    let showAccount: Bool // Whether to show account name (useful in global transaction lists)
    let showEvent: Bool // Whether to show event tag
    let onTap: (() -> Void)? // Optional tap handler for navigation
    
    @EnvironmentObject var appStore: AppStore
    
    // Convenience initializers for common use cases
    init(transaction: Transaction, showAccount: Bool = false, showEvent: Bool = true, onTap: (() -> Void)? = nil) {
        self.transaction = transaction
        self.showAccount = showAccount
        self.showEvent = showEvent
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Transaction type icon
                transactionIcon
                
                // Transaction info
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.description)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Metadata row
                    HStack(spacing: 8) {
                        Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let category = associatedCategory {
                            Text("• \(category.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if showAccount, let account = associatedAccount {
                            Text("• \(account.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if showEvent, let event = associatedEvent {
                            Text("• \(event.name)")
                                .font(.caption)
                                .foregroundColor(Color(hex: event.color))
                        }
                    }
                }
                
                Spacer()
                
                // Amount and status
                VStack(alignment: .trailing, spacing: 4) {
                    Text(transaction.amount.formattedAsCurrency)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(amountColor)
                    
                    if transaction.isScheduled {
                        statusBadge
                    }
                }
                
                // Chevron for navigation (only if onTap provided)
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
    
    // MARK: - Computed Properties
    
    private var associatedAccount: Account? {
        appStore.accounts.first { $0.id == transaction.accountId }
    }
    
    private var associatedCategory: Category? {
        guard let categoryId = transaction.categoryId else { return nil }
        return appStore.categories.first { $0.id == categoryId }
    }
    
    private var associatedEvent: Event? {
        guard let eventId = transaction.eventId else { return nil }
        return appStore.events.first { $0.id == eventId }
    }
    
    private var amountColor: Color {
        transaction.amount >= 0 ? .green : .primary
    }
    
    // MARK: - View Components
    
    private var transactionIcon: some View {
        ZStack {
            Circle()
                .fill(transaction.amount >= 0 ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                .frame(width: 36, height: 36)
            
            Image(systemName: iconName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(transaction.amount >= 0 ? .green : .red)
        }
    }
    
    private var iconName: String {
        if let categoryId = transaction.categoryId,
           let category = appStore.categories.first(where: { $0.id == categoryId }) {
            return category.icon
        }
        
        // Fallback to generic icons
        return transaction.amount >= 0 ? "arrow.down" : "arrow.up"
    }
    
    private var statusBadge: some View {
        Text(transaction.isScheduled ? "Scheduled" : "Completed")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(transaction.isScheduled ? .orange : .green)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(transaction.isScheduled ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
            )
    }
}

// MARK: - Preview Provider
struct TransactionRowView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppStore = AppStore()
        
        VStack(spacing: 16) {
            // Income transaction
            TransactionRowView(
                transaction: Transaction(
                    userId: "test",
                    accountId: "acc-current",
                    categoryId: "cat-salary",
                    amount: 2800.00,
                    description: "Monthly Salary"
                ),
                showAccount: true,
                onTap: { print("Tapped income transaction") }
            )
            
            Divider()
            
            // Expense transaction with event
            TransactionRowView(
                transaction: Transaction(
                    userId: "test",
                    accountId: "acc-current",
                    categoryId: "cat-food",
                    eventId: "event-paris",
                    amount: -45.80,
                    description: "Café de Flore"
                ),
                showAccount: false,
                onTap: { print("Tapped expense transaction") }
            )
            
            Divider()
            
            // Scheduled transaction
            TransactionRowView(
                transaction: Transaction(
                    userId: "test",
                    accountId: "acc-loan",
                    amount: -320.50,
                    description: "Car Finance Payment",
                    isScheduled: true
                ),
                showAccount: true
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .environmentObject(mockAppStore)
    }
}