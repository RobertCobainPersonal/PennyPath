//
//  SimplifiedAddTransactionView.swift
//  PennyPath
//
//  Created by Robert Cobain on 21/06/2025.
//

import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var appStore: AppStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var formState: TransactionFormState
    
    let preselectedAccountId: String?
    
    init(preselectedAccountId: String? = nil) {
        self.preselectedAccountId = preselectedAccountId
        self._formState = StateObject(wrappedValue: TransactionFormState())
    }
    
    var body: some View {
        NavigationView {
            TransactionFormView(
                formState: formState,
                isEditMode: false,
                onSave: saveTransaction,
                onCancel: { dismiss() }
            )
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupDefaults()
            }
        }
    }
    
    private func setupDefaults() {
        if let preselectedId = preselectedAccountId {
            formState.selectedAccountId = preselectedId
        } else {
            // Default to current account
            if let currentAccount = appStore.accounts.first(where: { $0.type == .current }) {
                formState.selectedAccountId = currentAccount.id
            } else if let firstAccount = appStore.accounts.first {
                formState.selectedAccountId = firstAccount.id
            }
        }
    }
    
    private func saveTransaction() {
        guard formState.isFormValid(appStore: appStore) else { return }
        
        formState.isLoading = true
        
        if formState.transactionType == .transfer {
            saveTransfer()
        } else if formState.isBNPLPurchase {
            saveBNPLTransaction()
        } else {
            saveRegularTransaction()
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        formState.isLoading = false
        dismiss()
    }
    
    private func saveRegularTransaction() {
        let transactionAmount = (Double(formState.amount) ?? 0) * (formState.transactionType == .income ? 1 : -1)
        
        let newTransaction = Transaction(
            userId: appStore.currentUser?.id ?? "mock-user-id",
            accountId: formState.selectedAccountId,
            categoryId: formState.selectedCategoryId.isEmpty ? nil : formState.selectedCategoryId,
            eventId: formState.selectedEventId.isEmpty ? nil : formState.selectedEventId,
            amount: transactionAmount,
            description: formState.merchant,
            date: formState.transactionDate
        )
        
        appStore.transactions.append(newTransaction)
        
        if let accountIndex = appStore.accounts.firstIndex(where: { $0.id == formState.selectedAccountId }) {
            appStore.accounts[accountIndex].balance += transactionAmount
        }
        
        print("📊 \(formState.transactionType.rawValue.capitalized) transaction created: \(formState.merchant)")
    }
    
    private func saveBNPLTransaction() {
        print("💳 BNPL transaction created: \(formState.merchant)")
        print("   Provider: \(formState.bnplProvider), Plan: \(formState.bnplPlan)")
        
        // For now, save as regular transaction
        saveRegularTransaction()
    }
    
    private func saveTransfer() {
        guard let transferAmount = Double(formState.amount) else { return }
        
        let newTransfer = Transfer(
            userId: appStore.currentUser?.id ?? "mock-user-id",
            fromAccountId: formState.selectedAccountId,
            toAccountId: formState.selectedToAccountId,
            amount: transferAmount,
            description: formState.merchant,
            date: formState.transactionDate,
            transferType: .manual
        )
        
        appStore.transfers.append(newTransfer)
        
        let (fromTransaction, toTransaction) = newTransfer.generateTransactions()
        appStore.transactions.append(fromTransaction)
        appStore.transactions.append(toTransaction)
        
        if let fromIndex = appStore.accounts.firstIndex(where: { $0.id == formState.selectedAccountId }) {
            appStore.accounts[fromIndex].balance -= transferAmount
        }
        if let toIndex = appStore.accounts.firstIndex(where: { $0.id == formState.selectedToAccountId }) {
            appStore.accounts[toIndex].balance += transferAmount
        }
        
        print("🔄 Transfer created: £\(transferAmount)")
    }
}

struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddTransactionView()
                .environmentObject(AppStore())
                .previewDisplayName("Add Transaction")
        }
    }
}
