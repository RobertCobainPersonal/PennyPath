//
//  TransactionFormView.swift
//  PennyPath
//
//  Created by Robert Cobain on 21/06/2025.
//

import SwiftUI

/// Shared transaction form layout used by both Add and Edit transaction views
struct TransactionFormView: View {
    @EnvironmentObject var appStore: AppStore
    @ObservedObject var formState: TransactionFormState
    let isEditMode: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Transaction Type Toggle
                TransactionTypeToggleSection(formState: formState, isEditMode: isEditMode)
                
                // Amount Entry Section
                AmountEntrySection(formState: formState)
                
                // Quick Amounts (only for income/expense)
                if formState.transactionType != .transfer {
                    QuickAmountsSection(formState: formState)
                }
                
                // Account Selection (different for transfers)
                // This now includes the BNPL toggle for expense transactions
                if formState.transactionType == .transfer {
                    TransferAccountsSection(formState: formState)
                } else {
                    AccountSelectionSection(formState: formState)
                }
                
                // BNPL Details Section (only when BNPL is enabled)
                // MOVED: This now appears right after account selection
                if formState.isBNPLPurchase && formState.transactionType == .expense {
                    BNPLDetailsSection(formState: formState)
                }
                
                // Merchant/Source/Description Section
                // MOVED: This now appears after BNPL details
                MerchantEntrySection(formState: formState)
                
                // Category Selection (not for transfers)
                if formState.transactionType != .transfer {
                    CategorySelectionSection(formState: formState)
                }
                
                // Event Selection (for all transaction types)
                EventSelectionSection(formState: formState)
                
                // Business Expense Toggle (only for expenses)
                if formState.transactionType == .expense {
                    BusinessExpenseSection(formState: formState)
                }
                
                // Date Selection
                DateSelectionSection(formState: formState)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    onCancel()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    onSave()
                }
                .fontWeight(.semibold)
                .disabled(!formState.isFormValid || formState.isLoading)
            }
        }
        .alert("Error", isPresented: $formState.showingError) {
            Button("OK") { }
        } message: {
            Text(formState.errorMessage)
        }
    }
}

// MARK: - Preview Provider
struct TransactionFormView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TransactionFormView(
                formState: TransactionFormState(),
                isEditMode: false,
                onSave: { print("Save tapped") },
                onCancel: { print("Cancel tapped") }
            )
            .navigationTitle("Transaction Form")
            .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(AppStore())
    }
}
