//
//  AccountPicker.swift
//  PennyPath
//
//  Created by Robert Cobain on 17/06/2025.
//


//
//  AccountPicker.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

/// Reusable account picker component
/// Used in AddTransaction, transfers, budget setup, and filtering
struct AccountPicker: View {
    @EnvironmentObject var appStore: AppStore
    @Binding var selectedAccountId: String
    let placeholder: String
    let accountFilter: ((Account) -> Bool)?
    let showBalance: Bool
    let isRequired: Bool
    
    init(
        selectedAccountId: Binding<String>,
        placeholder: String = "Select Account",
        accountFilter: ((Account) -> Bool)? = nil,
        showBalance: Bool = false,
        isRequired: Bool = true
    ) {
        self._selectedAccountId = selectedAccountId
        self.placeholder = placeholder
        self.accountFilter = accountFilter
        self.showBalance = showBalance
        self.isRequired = isRequired
    }
    
    private var filteredAccounts: [Account] {
        if let filter = accountFilter {
            return appStore.accounts.filter(filter)
        }
        return appStore.accounts
    }
    
    private var selectedAccount: Account? {
        filteredAccounts.first { $0.id == selectedAccountId }
    }
    
    var body: some View {
        Menu {
            if !isRequired {
                Button("None") {
                    selectedAccountId = ""
                }
                
                if !filteredAccounts.isEmpty {
                    Divider()
                }
            }
            
            ForEach(filteredAccounts) { account in
                Button(action: {
                    selectedAccountId = account.id
                }) {
                    HStack {
                        Image(systemName: account.type.icon)
                            .foregroundColor(Color(hex: account.type.color))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .fontWeight(.medium)
                            
                            if showBalance {
                                Text(account.balance.formattedAsCurrency)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(account.type.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if account.id == selectedAccountId {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        } label: {
            HStack {
                if let account = selectedAccount {
                    Image(systemName: account.type.icon)
                        .foregroundColor(Color(hex: account.type.color))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                        
                        if showBalance {
                            Text(account.balance.formattedAsCurrency)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text(account.type.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

/// Specialized account picker for transfers (excludes the selected "from" account)
struct TransferAccountPicker: View {
    @Binding var fromAccountId: String
    @Binding var toAccountId: String
    let label: String
    let isDestination: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.headline)
                .fontWeight(.semibold)
            
            AccountPicker(
                selectedAccountId: isDestination ? $toAccountId : $fromAccountId,
                placeholder: isDestination ? "Select destination account" : "Select source account",
                accountFilter: { account in
                    // For destination, exclude the source account
                    if isDestination {
                        return account.id != fromAccountId
                    }
                    // For source, exclude the destination account
                    return account.id != toAccountId
                },
                showBalance: true
            )
        }
    }
}

/// Compact account picker for inline use (smaller padding, single line)
struct CompactAccountPicker: View {
    @Binding var selectedAccountId: String
    let placeholder: String
    let accountFilter: ((Account) -> Bool)?
    
    init(
        selectedAccountId: Binding<String>,
        placeholder: String = "Account",
        accountFilter: ((Account) -> Bool)? = nil
    ) {
        self._selectedAccountId = selectedAccountId
        self.placeholder = placeholder
        self.accountFilter = accountFilter
    }
    
    var body: some View {
        AccountPicker(
            selectedAccountId: $selectedAccountId,
            placeholder: placeholder,
            accountFilter: accountFilter,
            showBalance: false
        )
        .frame(height: 44) // Compact height
    }
}

/// Account filter utilities for common use cases
struct AccountFilters {
    /// Only accounts that can receive money (positive balance accounts)
    static let canReceiveMoney: (Account) -> Bool = { account in
        account.type.canHavePositiveBalance
    }
    
    /// Only accounts that can send money (have positive balance)
    static let canSendMoney: (Account) -> Bool = { account in
        account.balance > 0
    }
    
    /// Only traditional banking accounts (current, savings)
    static let traditionalBanking: (Account) -> Bool = { account in
        [.current, .savings].contains(account.type)
    }
    
    /// Only credit/debt accounts
    static let creditAccounts: (Account) -> Bool = { account in
        [.credit, .loan, .bnpl, .familyFriend, .debtCollection].contains(account.type)
    }
    
    /// Only accounts that support scheduled payments
    static let supportsScheduledPayments: (Account) -> Bool = { account in
        account.type.supportsScheduledPayments
    }
}

// MARK: - Preview Provider
struct AccountPicker_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppStore = AppStore()
        
        ScrollView {
            VStack(spacing: 20) {
                // Standard account picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard Account Picker")
                        .font(.headline)
                    
                    AccountPicker(
                        selectedAccountId: .constant("acc-current"),
                        placeholder: "Select Account"
                    )
                }
                
                Divider()
                
                // Account picker with balance
                VStack(alignment: .leading, spacing: 8) {
                    Text("With Balance Display")
                        .font(.headline)
                    
                    AccountPicker(
                        selectedAccountId: .constant("acc-savings"),
                        placeholder: "Select Account",
                        showBalance: true
                    )
                }
                
                Divider()
                
                // Filtered account picker (only traditional banking)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filtered (Banking Only)")
                        .font(.headline)
                    
                    AccountPicker(
                        selectedAccountId: .constant(""),
                        placeholder: "Select Banking Account",
                        accountFilter: AccountFilters.traditionalBanking
                    )
                }
                
                Divider()
                
                // Transfer account pickers
                VStack(alignment: .leading, spacing: 16) {
                    Text("Transfer Pickers")
                        .font(.headline)
                    
                    TransferAccountPicker(
                        fromAccountId: .constant("acc-current"),
                        toAccountId: .constant(""),
                        label: "From Account",
                        isDestination: false
                    )
                    
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    
                    TransferAccountPicker(
                        fromAccountId: .constant("acc-current"),
                        toAccountId: .constant(""),
                        label: "To Account",
                        isDestination: true
                    )
                }
                
                Divider()
                
                // Compact picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Compact Picker")
                        .font(.headline)
                    
                    CompactAccountPicker(
                        selectedAccountId: .constant("acc-credit"),
                        placeholder: "Account"
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .environmentObject(mockAppStore)
    }
}