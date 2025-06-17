//
//  AccountRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 17/06/2025.
//

import SwiftUI

/// Reusable component for displaying account information in lists
/// Used in AccountsList, account pickers, search results, and transfer selection
struct AccountRowView: View {
    let account: Account
    let showBalance: Bool
    let showTrend: Bool
    let showChevron: Bool
    let isSelected: Bool
    let onTap: (() -> Void)?
    let navigationDestination: AnyView? // NEW: Optional navigation destination
    
    @EnvironmentObject var appStore: AppStore
    
    // Convenience initializers for common use cases
    init(
        account: Account,
        showBalance: Bool = true,
        showTrend: Bool = true,
        showChevron: Bool = true,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil,
        navigationDestination: AnyView? = nil
    ) {
        self.account = account
        self.showBalance = showBalance
        self.showTrend = showTrend
        self.showChevron = showChevron
        self.isSelected = isSelected
        self.onTap = onTap
        self.navigationDestination = navigationDestination
    }
    
    var body: some View {
        Group {
            if let destination = navigationDestination {
                NavigationLink(destination: destination) {
                    rowContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: {
                    onTap?()
                }) {
                    rowContent
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(onTap == nil && !isSelected)
            }
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: 12) {
            // Account type icon
            accountIcon
            
            // Account info
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(account.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Additional info for specific account types
                    if let additionalInfo = accountAdditionalInfo {
                        Text("• \(additionalInfo)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Balance and trend section
            if showBalance {
                balanceSection
            }
            
            // Selection indicator or chevron
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
    }
    
    // MARK: - Computed Properties
    
    private var accountAdditionalInfo: String? {
        switch account.type {
        case .credit:
            if let utilization = account.creditUtilization {
                return "\(Int(utilization * 100))% used"
            }
        case .loan:
            if let progress = account.loanProgress {
                return "\(Int(progress * 100))% paid"
            }
        case .bnpl:
            if let provider = account.bnplProvider {
                return provider
            }
        default:
            break
        }
        return nil
    }
    
    // MARK: - View Components
    
    private var accountIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: account.type.color).opacity(0.15))
                .frame(width: 44, height: 44)
            
            Image(systemName: account.type.icon)
                .font(.headline)
                .foregroundColor(Color(hex: account.type.color))
        }
    }
    
    private var balanceSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(account.balance.formattedAsCurrency)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(account.balance >= 0 ? .primary : .red)
            
            if showTrend {
                trendIndicator
            }
        }
    }
    
    private var trendIndicator: some View {
        HStack(spacing: 4) {
            // Simple trend indicator (could be enhanced with real trend data)
            Image(systemName: "minus")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("No change")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Specialized Account Row Variants

/// Simplified account row for pickers (no trend, smaller size)
struct AccountPickerRow: View {
    let account: Account
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        AccountRowView(
            account: account,
            showBalance: true,
            showTrend: false,
            showChevron: false,
            isSelected: isSelected,
            onTap: onTap
        )
        .padding(.horizontal, 4)
    }
}

/// Account row for balance-only displays (transfers, summaries)
struct AccountBalanceRow: View {
    let account: Account
    let onTap: (() -> Void)? = nil
    
    var body: some View {
        AccountRowView(
            account: account,
            showBalance: true,
            showTrend: false,
            showChevron: onTap != nil,
            onTap: onTap
        )
    }
}

// MARK: - Preview Provider
struct AccountRowView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppStore = AppStore()
        
        ScrollView {
            VStack(spacing: 16) {
                // Standard account row (as used in AccountsList)
                AccountRowView(
                    account: Account(
                        userId: "test",
                        name: "Barclays Current Account",
                        type: .current,
                        balance: 2850.75
                    ),
                    onTap: { print("Tapped current account") }
                )
                
                Divider()
                
                // Credit card with utilization
                AccountRowView(
                    account: Account(
                        userId: "test",
                        name: "Santander Cashback Credit Card",
                        type: .credit,
                        balance: -892.45,
                        creditLimit: 3000.00
                    ),
                    onTap: { print("Tapped credit card") }
                )
                
                Divider()
                
                // Loan with progress
                AccountRowView(
                    account: Account(
                        userId: "test",
                        name: "Lloyds Car Finance",
                        type: .loan,
                        balance: -12750.00,
                        originalLoanAmount: 18000.00,
                        loanTermMonths: 48,
                        loanStartDate: Calendar.current.date(byAdding: .month, value: -18, to: Date())
                    ),
                    onTap: { print("Tapped loan") }
                )
                
                Divider()
                
                // BNPL account
                AccountRowView(
                    account: Account(
                        userId: "test",
                        name: "Klarna",
                        type: .bnpl,
                        balance: -124.97,
                        bnplProvider: "Klarna"
                    ),
                    onTap: { print("Tapped BNPL") }
                )
                
                Divider()
                
                // Picker variant (selected)
                Text("Picker Variant:")
                    .font(.headline)
                    .padding(.top)
                
                AccountPickerRow(
                    account: Account(
                        userId: "test",
                        name: "HSBC Instant Saver",
                        type: .savings,
                        balance: 8420.00
                    ),
                    isSelected: true,
                    onTap: { print("Selected savings account") }
                )
                
                // Picker variant (not selected)
                AccountPickerRow(
                    account: Account(
                        userId: "test",
                        name: "Investment Account",
                        type: .investment,
                        balance: 15000.00
                    ),
                    isSelected: false,
                    onTap: { print("Selected investment account") }
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .environmentObject(mockAppStore)
    }
}
