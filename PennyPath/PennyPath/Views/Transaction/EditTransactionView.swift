//
//  SimplifiedEditTransactionView.swift
//  PennyPath
//
//  Created by Robert Cobain on 21/06/2025.
//

import SwiftUI

struct EditTransactionView: View {
    @EnvironmentObject var appStore: AppStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var formState: TransactionFormState
    
    let originalTransaction: Transaction
    
    init(transaction: Transaction) {
        self.originalTransaction = transaction
        self._formState = StateObject(wrappedValue: TransactionFormState(transaction: transaction))
    }
    
    var body: some View {
        NavigationView {
            TransactionFormView(
                formState: formState,
                isEditMode: true,
                onSave: saveTransaction,
                onCancel: { dismiss() }
            )
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveTransaction() {
        guard formState.isFormValid(appStore: appStore) else { return }
        
        formState.isLoading = true
        
        let oldAmount = originalTransaction.amount
        let newAmount = (Double(formState.amount) ?? 0) * (formState.transactionType == .income ? 1 : -1)
        let amountDifference = newAmount - oldAmount
        
        let updatedTransaction = Transaction(
            id: originalTransaction.id,
            userId: originalTransaction.userId,
            accountId: formState.selectedAccountId,
            categoryId: formState.selectedCategoryId.isEmpty ? nil : formState.selectedCategoryId,
            bnplPlanId: originalTransaction.bnplPlanId,
            eventId: formState.selectedEventId.isEmpty ? nil : formState.selectedEventId,
            amount: newAmount,
            description: formState.merchant,
            date: formState.transactionDate,
            isScheduled: originalTransaction.isScheduled,
            recurrence: originalTransaction.recurrence
        )
        
        if let index = appStore.transactions.firstIndex(where: { $0.id == originalTransaction.id }) {
            appStore.transactions[index] = updatedTransaction
        }
        
        // Update account balances
        if formState.selectedAccountId != originalTransaction.accountId {
            // Account changed
            if let oldAccountIndex = appStore.accounts.firstIndex(where: { $0.id == originalTransaction.accountId }) {
                appStore.accounts[oldAccountIndex].balance -= oldAmount
            }
            if let newAccountIndex = appStore.accounts.firstIndex(where: { $0.id == formState.selectedAccountId }) {
                appStore.accounts[newAccountIndex].balance += newAmount
            }
        } else {
            // Same account - adjust by difference
            if let accountIndex = appStore.accounts.firstIndex(where: { $0.id == formState.selectedAccountId }) {
                appStore.accounts[accountIndex].balance += amountDifference
            }
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("✏️ Transaction updated: \(formState.merchant)")
        
        formState.isLoading = false
        dismiss()
    }
}
