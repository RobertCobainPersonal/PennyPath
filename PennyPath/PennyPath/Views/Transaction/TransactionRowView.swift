//
//  TransactionRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 17/06/2025.
//

import SwiftUI

/// Reusable component for displaying transaction information in lists
/// Used across AccountDetail, TransactionsList, Dashboard, and search results
struct TransactionRowView: View {
    let transaction: Transaction
    let showAccount: Bool // Whether to show account name (useful in global transaction lists)
    let showEvent: Bool // Whether to show event tag
    let showDate: Bool // Whether to show date (false when grouped by date)
    let style: TransactionRowStyle // Visual style variant
    let showDueContext: Bool // Whether to show "Due in X days" instead of date
    let onTap: (() -> Void)? // Optional tap handler for navigation
    
    @EnvironmentObject var appStore: AppStore
    
    // Convenience initializer with new parameters
    init(
        transaction: Transaction,
        showAccount: Bool = false,
        showEvent: Bool = true,
        showDate: Bool = true,
        style: TransactionRowStyle = .card,
        showDueContext: Bool = false, // NEW: Show temporal context
        onTap: (() -> Void)? = nil
    ) {
        self.transaction = transaction
        self.showAccount = showAccount
        self.showEvent = showEvent
        self.showDate = showDate
        self.style = style
        self.showDueContext = showDueContext
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 16) {
                // Category icon (or fallback for uncategorized)
                categoryIcon
                
                // Transaction info
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.description)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary) // Force primary color
                        .lineLimit(1)
                    
                    // Simplified metadata row
                    metadataRow
                }
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text(transaction.amount.formattedAsCurrency)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(amountColor == .green ? .green : .red) // Ensure colors stick
                    
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
            .padding(.horizontal, 20)
            .padding(.vertical, style == .compact ? 12 : 16) // Reduced padding for compact style
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
        transaction.amount >= 0 ? .green : .red
    }
    
    // MARK: - View Components
    
    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 44, height: 44)
            
            Image(systemName: iconName)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(iconForegroundColor)
        }
    }
    
    private var iconName: String {
        if let category = associatedCategory {
            return category.icon
        }
        
        // Fallback to transaction type icons
        if transaction.categoryId == nil {
            return "arrow.left.arrow.right" // Transfer
        }
        
        return transaction.amount >= 0 ? "arrow.down" : "arrow.up"
    }
    
    private var iconBackgroundColor: Color {
        if let category = associatedCategory {
            return Color(hex: category.color).opacity(0.15)
        }
        
        // Softer fallback colors
        return transaction.amount >= 0 ? Color.green.opacity(0.15) : Color.blue.opacity(0.15)
    }
    
    private var iconForegroundColor: Color {
        if let category = associatedCategory {
            return Color(hex: category.color)
        }
        
        // Softer fallback colors
        return transaction.amount >= 0 ? .green : .blue
    }
    
    private var metadataRow: some View {
        HStack(spacing: 8) {
            // Show account name if requested
            if showAccount, let account = associatedAccount {
                Text(account.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .colorMultiply(.primary) // Force override NavigationLink color
            }
            
            // Show event if present and requested
            if showEvent, let event = associatedEvent {
                if showAccount && associatedAccount != nil {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(event.name)
                    .font(.caption)
                    .foregroundColor(Color(hex: event.color))
            }
            
            // Show date if requested (for non-grouped views)
            if showDate {
                if (showAccount && associatedAccount != nil) || (showEvent && associatedEvent != nil) {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if showDueContext && transaction.isScheduled {
                    Text(dueText)
                        .font(.caption)
                        .foregroundColor(dueTextColor)
                } else {
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var statusBadge: some View {
        // Only show "Scheduled" badge when not in upcoming transactions context
        Group {
            if transaction.isScheduled && style != .compact {
                Text("Scheduled")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.15))
                    )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: transaction.date).day ?? 0
    }
    
    private var dueText: String {
        let days = daysUntilDue
        
        if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else if days > 1 {
            return "Due in \(days) days"
        } else {
            return "Overdue"
        }
    }
    
    private var dueTextColor: Color {
        let days = daysUntilDue
        
        if days <= 0 {
            return .red // Today or overdue
        } else if days == 1 {
            return .orange // Tomorrow
        } else {
            return .secondary // Future
        }
    }
}

// MARK: - Transaction Row Styles

enum TransactionRowStyle {
    case card // Original style with card background
    case fullWidth // Full width, no card background (iOS Settings style)
    case compact // Smaller padding for dense lists, no "Scheduled" badges
}

// MARK: - Preview Provider
struct TransactionRowView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppStore = AppStore()
        
        VStack(spacing: 0) {
            // Income transaction with account shown
            TransactionRowView(
                transaction: Transaction(
                    userId: "test",
                    accountId: "acc-current",
                    categoryId: "cat-salary",
                    amount: 2800.00,
                    description: "Monthly Salary"
                ),
                showAccount: true,
                showDate: false,
                onTap: { print("Tapped income transaction") }
            )
            
            Divider()
                .padding(.leading, 64)
            
            // Expense transaction with due context
            TransactionRowView(
                transaction: Transaction(
                    userId: "test",
                    accountId: "acc-current",
                    categoryId: "cat-food",
                    eventId: "event-paris",
                    amount: -45.80,
                    description: "Café de Flore",
                    date: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                    isScheduled: true
                ),
                showAccount: false,
                showEvent: true,
                showDate: true,
                style: .compact,
                showDueContext: true
            )
            
            Divider()
                .padding(.leading, 64)
            
            // Regular transaction
            TransactionRowView(
                transaction: Transaction(
                    userId: "test",
                    accountId: "acc-loan",
                    amount: -320.50,
                    description: "Car Finance Payment",
                    isScheduled: true
                ),
                showAccount: true,
                showEvent: true,
                showDate: true
            )
        }
        .background(Color(.systemBackground))
        .environmentObject(mockAppStore)
    }
}
