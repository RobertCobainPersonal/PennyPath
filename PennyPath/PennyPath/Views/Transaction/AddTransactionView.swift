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
    
    // MARK: - Main Save Logic
    
    private func saveTransaction() {
        guard formState.isFormValid(appStore: appStore) else {
            print("❌ Form validation failed")
            return
        }
        
        formState.isLoading = true
        
        do {
            if formState.transactionType == .transfer {
                try saveTransfer()
            } else if formState.isBNPLPurchase {
                try saveBNPLTransaction()
            } else {
                try saveRegularTransaction()
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            formState.isLoading = false
            dismiss()
            
        } catch {
            formState.isLoading = false
            formState.errorMessage = error.localizedDescription
            formState.showingError = true
            print("❌ Error saving transaction: \(error)")
        }
    }
    
    // MARK: - Regular Transaction Save
    
    private func saveRegularTransaction() throws {
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
        
        // Add to AppStore using existing method
        appStore.transactions.append(newTransaction)
        updateAccountBalance(accountId: formState.selectedAccountId, amount: transactionAmount)
        
        print("✅ Regular transaction saved: \(formState.merchant) - \(transactionAmount.formattedAsCurrency)")
    }
    
    // MARK: - Transfer Save
    
    private func saveTransfer() throws {
        guard let amount = Double(formState.amount), amount > 0 else {
            throw TransactionError.invalidAmount
        }
        
        // Create outgoing transaction (from account)
        let outgoingTransaction = Transaction(
            userId: appStore.currentUser?.id ?? "mock-user-id",
            accountId: formState.selectedAccountId,
            categoryId: nil, // Transfers have no category
            eventId: formState.selectedEventId.isEmpty ? nil : formState.selectedEventId,
            amount: -amount,
            description: formState.merchant,
            date: formState.transactionDate
        )
        
        // Create incoming transaction (to account)
        let incomingTransaction = Transaction(
            userId: appStore.currentUser?.id ?? "mock-user-id",
            accountId: formState.selectedToAccountId,
            categoryId: nil, // Transfers have no category
            eventId: formState.selectedEventId.isEmpty ? nil : formState.selectedEventId,
            amount: amount,
            description: formState.merchant,
            date: formState.transactionDate
        )
        
        // Add both transactions using existing pattern
        appStore.transactions.append(outgoingTransaction)
        appStore.transactions.append(incomingTransaction)
        
        // Update account balances
        updateAccountBalance(accountId: formState.selectedAccountId, amount: -amount)
        updateAccountBalance(accountId: formState.selectedToAccountId, amount: amount)
        
        print("✅ Transfer saved: \(amount.formattedAsCurrency) from \(formState.selectedAccountId) to \(formState.selectedToAccountId)")
    }
    
    // MARK: - BNPL Transaction Save (SIMPLIFIED COMPATIBLE VERSION)
    
    private func saveBNPLTransaction() throws {
        guard let purchaseAmount = Double(formState.amount), purchaseAmount > 0 else {
            throw TransactionError.invalidAmount
        }
        
        guard !formState.bnplProvider.isEmpty && !formState.bnplPlan.isEmpty else {
            throw TransactionError.bnplMissingPlan
        }
        
        let upfrontFee = Double(formState.upfrontFee) ?? 0
        let totalCost = purchaseAmount + upfrontFee
        
        // Calculate payment breakdown using the same logic from our UI
        let numberOfPayments = getNumberOfPayments(for: formState.bnplPlan)
        let installmentAmount = purchaseAmount / Double(numberOfPayments)
        let frequency = getPaymentFrequency(for: formState.bnplPlan)
        
        print("💳 Creating BNPL transaction:")
        print("   Purchase: \(purchaseAmount.formattedAsCurrency)")
        print("   Upfront Fee: \(upfrontFee.formattedAsCurrency)")
        print("   Total Cost: \(totalCost.formattedAsCurrency)")
        print("   \(numberOfPayments) payments of \(installmentAmount.formattedAsCurrency)")
        
        // 1. Create main purchase transaction
        let purchaseTransaction = Transaction(
            userId: appStore.currentUser?.id ?? "mock-user-id",
            accountId: formState.selectedAccountId,
            categoryId: formState.selectedCategoryId.isEmpty ? nil : formState.selectedCategoryId,
            eventId: formState.selectedEventId.isEmpty ? nil : formState.selectedEventId,
            amount: -purchaseAmount,
            description: "\(formState.merchant) (BNPL: \(formState.bnplProvider))",
            date: formState.transactionDate
        )
        
        // 2. Create upfront fee transaction (if there's a fee)
        var upfrontTransaction: Transaction?
        if upfrontFee > 0 {
            upfrontTransaction = Transaction(
                userId: appStore.currentUser?.id ?? "mock-user-id",
                accountId: formState.selectedAccountId,
                categoryId: formState.selectedCategoryId.isEmpty ? nil : formState.selectedCategoryId,
                eventId: formState.selectedEventId.isEmpty ? nil : formState.selectedEventId,
                amount: -upfrontFee,
                description: "\(formState.merchant) - BNPL Fee (\(formState.bnplProvider))",
                date: formState.transactionDate
            )
        }
        
        // 3. Create scheduled installment transactions
        let paymentDates = generatePaymentDates(
            numberOfPayments: numberOfPayments,
            frequency: frequency,
            startDate: formState.transactionDate
        )
        
        var scheduledTransactions: [Transaction] = []
        for (index, paymentDate) in paymentDates.enumerated() {
            let scheduledTransaction = Transaction(
                userId: appStore.currentUser?.id ?? "mock-user-id",
                accountId: formState.selectedAccountId,
                categoryId: formState.selectedCategoryId.isEmpty ? nil : formState.selectedCategoryId,
                eventId: formState.selectedEventId.isEmpty ? nil : formState.selectedEventId,
                amount: -installmentAmount,
                description: "\(formState.merchant) - Payment \(index + 1)/\(numberOfPayments) (\(formState.bnplProvider))",
                date: paymentDate,
                isScheduled: true
            )
            scheduledTransactions.append(scheduledTransaction)
        }
        
        // 4. Save all transactions using existing AppStore pattern
        appStore.transactions.append(purchaseTransaction)
        
        if let upfront = upfrontTransaction {
            appStore.transactions.append(upfront)
        }
        
        for scheduled in scheduledTransactions {
            appStore.transactions.append(scheduled)
        }
        
        // 5. Update account balance (total cost comes out immediately)
        updateAccountBalance(accountId: formState.selectedAccountId, amount: -totalCost)
        
        print("✅ BNPL transaction saved successfully!")
        print("   Created \(1 + (upfrontTransaction != nil ? 1 : 0) + scheduledTransactions.count) transaction records")
        
        // Optional: Create simple BNPL plan record for tracking (commented out for now)
        // let bnplPlan = BNPLPlan(...)
        // appStore.bnplPlans.append(bnplPlan)
    }
    
    // MARK: - BNPL Helper Methods
    
    private func getNumberOfPayments(for plan: String) -> Int {
        switch plan.lowercased() {
        case let p where p.contains("pay in 3"):
            return 3
        case let p where p.contains("pay in 4"):
            return 4
        case let p where p.contains("pay in 6"):
            return 6
        case let p where p.contains("4 weeks"):
            return 4
        case let p where p.contains("6 weeks"):
            return 6
        case let p where p.contains("30 days"):
            return 1
        default:
            return 3 // Default fallback
        }
    }
    
    private func getPaymentFrequency(for plan: String) -> PaymentFrequency {
        switch plan.lowercased() {
        case let p where p.contains("weekly"):
            return .weekly
        case let p where p.contains("fortnightly"):
            return .biweekly
        case let p where p.contains("monthly"):
            return .monthly
        case let p where p.contains("weeks"):
            return .weekly
        case let p where p.contains("30 days"):
            return .monthly
        default:
            return .biweekly // Default for most BNPL
        }
    }
    
    private func generatePaymentDates(numberOfPayments: Int, frequency: PaymentFrequency, startDate: Date) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        
        for i in 1...numberOfPayments {
            let paymentDate: Date
            
            switch frequency {
            case .daily:
                paymentDate = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            case .weekly:
                paymentDate = calendar.date(byAdding: .weekOfYear, value: i, to: startDate) ?? startDate
            case .biweekly:
                paymentDate = calendar.date(byAdding: .weekOfYear, value: i * 2, to: startDate) ?? startDate
            case .monthly:
                paymentDate = calendar.date(byAdding: .month, value: i, to: startDate) ?? startDate
            case .yearly:
                paymentDate = calendar.date(byAdding: .year, value: i, to: startDate) ?? startDate
            }
            
            dates.append(paymentDate)
        }
        
        return dates
    }
    
    // MARK: - Helper Methods
    
    private func updateAccountBalance(accountId: String, amount: Double) {
        if let accountIndex = appStore.accounts.firstIndex(where: { $0.id == accountId }) {
            appStore.accounts[accountIndex].balance += amount
            print("   💳 Account balance updated: \(appStore.accounts[accountIndex].balance.formattedAsCurrency)")
        }
    }
}

// MARK: - Transaction Errors

enum TransactionError: Error, LocalizedError {
    case invalidAmount
    case missingAccount
    case missingCategory
    case bnplMissingPlan
    case bnplCalculationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a valid amount"
        case .missingAccount:
            return "Please select an account"
        case .missingCategory:
            return "Please select a category"
        case .bnplMissingPlan:
            return "Please select a BNPL provider and plan"
        case .bnplCalculationFailed:
            return "Unable to calculate BNPL payment schedule"
        }
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
