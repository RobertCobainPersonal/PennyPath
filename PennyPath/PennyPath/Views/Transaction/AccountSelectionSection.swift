//
//  AccountSelectionSection.swift
//  PennyPath
//
//  Created by Robert Cobain on 21/06/2025.
//

import SwiftUI

/// Account selection component with integrated BNPL toggle and validation
struct AccountSelectionSection: View {
    @EnvironmentObject var appStore: AppStore
    @ObservedObject var formState: TransactionFormState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.headline)
                .fontWeight(.semibold)
            
            AccountPicker(
                selectedAccountId: $formState.selectedAccountId,
                placeholder: "Select Account",
                accountFilter: bnplAccountFilter,
                showBalance: true
            )
            .onChange(of: formState.selectedAccountId) { accountId in
                // Auto-populate BNPL provider when account changes
                if formState.isBNPLPurchase {
                    if let account = appStore.accounts.first(where: { $0.id == accountId }),
                       account.type == .bnpl {
                        formState.bnplProvider = account.bnplProvider ?? ""
                    }
                }
            }
            
            // BNPL Purchase Toggle (for expense transactions only)
            if formState.transactionType == .expense {
                bnplPurchaseToggle
            }
            
            // BNPL Account Validation Message
            if formState.isBNPLPurchase {
                bnplAccountValidationMessage
            }
        }
    }
    
    // MARK: - BNPL Toggle
    
    private var bnplPurchaseToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("BNPL Purchase")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Buy now, pay later in installments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $formState.isBNPLPurchase)
                .onChange(of: formState.isBNPLPurchase) { enabled in
                    if !enabled {
                        formState.clearBNPLFields()
                        // Clear account selection if it's a BNPL account
                        if let account = appStore.accounts.first(where: { $0.id == formState.selectedAccountId }),
                           account.type == .bnpl {
                            formState.selectedAccountId = ""
                        }
                    } else {
                        // When BNPL is enabled, try to auto-select appropriate account
                        autoSelectBNPLAccount()
                    }
                }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func autoSelectBNPLAccount() {
        // If current selection is not BNPL, try to find one
        let currentAccount = appStore.accounts.first(where: { $0.id == formState.selectedAccountId })
        if currentAccount?.type != .bnpl {
            // Find first available BNPL account
            if let bnplAccount = appStore.accounts.first(where: { $0.type == .bnpl }) {
                formState.selectedAccountId = bnplAccount.id
                // Auto-populate provider from the selected account
                formState.bnplProvider = bnplAccount.bnplProvider ?? ""
            } else {
                // Clear selection if no BNPL accounts exist
                formState.selectedAccountId = ""
            }
        } else {
            // Current account is already BNPL, populate provider
            formState.bnplProvider = currentAccount?.bnplProvider ?? ""
        }
    }
    
    // MARK: - BNPL Account Validation
    
    private var bnplAccountFilter: ((Account) -> Bool)? {
        guard formState.isBNPLPurchase else { return nil }
        return { account in account.type == .bnpl }
    }
    
    private var bnplAccountValidationMessage: some View {
        HStack(spacing: 8) {
            Image(systemName: selectedBNPLAccount != nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(selectedBNPLAccount != nil ? .green : .orange)
                .font(.caption)
            
            Text(bnplAccountValidationText)
                .font(.caption)
                .foregroundColor(selectedBNPLAccount != nil ? .green : .orange)
            
            Spacer()
            
            if appStore.accounts.filter({ $0.type == .bnpl }).isEmpty {
                Button("Create BNPL Account") {
                    print("🏦 Create BNPL account for \(formState.bnplProvider)")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((selectedBNPLAccount != nil ? Color.green : Color.orange).opacity(0.1))
        )
    }
    
    private var selectedBNPLAccount: Account? {
        guard formState.isBNPLPurchase,
              let account = appStore.accounts.first(where: { $0.id == formState.selectedAccountId }),
              account.type == .bnpl else { return nil }
        return account
    }
    
    private var bnplAccountValidationText: String {
        if !formState.isBNPLPurchase { return "" }
        
        if formState.selectedAccountId.isEmpty {
            return "Select a BNPL account for this purchase"
        }
        
        if let account = appStore.accounts.first(where: { $0.id == formState.selectedAccountId }) {
            if account.type == .bnpl {
                return "✓ BNPL account selected: \(account.name)"
            } else {
                return "⚠️ Please select a BNPL account (current selection: \(account.type.displayName))"
            }
        }
        
        return "Account not found"
    }
}


