//
//  AddExpenseViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AddExpenseViewModel: ObservableObject {
    @Published var amountStr: String = ""
    @Published var selectedAccountId: String = ""
    @Published var date: Date = Date()
    @Published var categoryId: String? = nil
    @Published var description: String = ""
    @Published var isBNPL: Bool = false
    @Published var selectedPlanId: String = ""
    @Published var selectedFundingAccountId: String = ""
    
    // --- Properties to handle editing ---
    private var transactionToEdit: Transaction?
    var navigationTitle: String {
        transactionToEdit == nil ? "New Expense" : "Edit Expense"
    }
    var saveButtonText: String {
        transactionToEdit == nil ? "Save Expense" : "Update Expense"
    }
    var isEditing: Bool {
        transactionToEdit != nil
    }

    var isFormValid: Bool {
        !(amountStr.isEmpty || selectedAccountId.isEmpty) &&
        (isBNPL ? !(selectedPlanId.isEmpty || selectedFundingAccountId.isEmpty) : true)
    }
    
    // --- Initializers ---
    
    // Default initializer for adding a new expense
    init() {
        self.transactionToEdit = nil
    }
    
    // Initializer for editing an existing expense
    init(transactionToEdit: Transaction) {
        self.transactionToEdit = transactionToEdit
        
        // Pre-populate fields
        // Note: Expense amounts are negative, so we use abs() for the text field
        self.amountStr = String(abs(transactionToEdit.amount))
        self.selectedAccountId = transactionToEdit.accountId
        self.date = transactionToEdit.date.dateValue()
        self.categoryId = transactionToEdit.categoryId
        self.description = transactionToEdit.description
        self.isBNPL = transactionToEdit.isBNPL
        
        if transactionToEdit.isBNPL {
            self.selectedPlanId = transactionToEdit.bnplPlanId ?? ""
            self.selectedFundingAccountId = transactionToEdit.linkedAccountId ?? ""
        }
    }

    func saveOrUpdate(plan: BNPLPlan?, schedule: BNPLSchedulePreview?) async throws {
        guard let userId = Auth.auth().currentUser?.uid, let amount = Double(amountStr) else {
            throw NSError(domain: "AddExpenseViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid data."])
        }
        
        if var transaction = transactionToEdit {
            // --- UPDATE LOGIC ---
            transaction.amount = -abs(amount) // Ensure amount is negative
            transaction.accountId = selectedAccountId
            transaction.date = Timestamp(date: date)
            transaction.description = description
            transaction.categoryId = self.categoryId
            // Note: Editing BNPL status is not supported in this version
            
            try await TransactionService.shared.updateTransaction(transaction)
            
        } else {
            // --- SAVE NEW LOGIC ---
            let details = TransactionDetails(
                amount: amount,
                accountId: selectedAccountId,
                date: date,
                description: description,
                categoryId: self.categoryId,
                isBNPL: isBNPL,
                bnplPlan: plan,
                bnplFundingAccountId: selectedFundingAccountId,
                bnplSchedule: schedule
            )
            try await TransactionService.shared.addTransaction(details: details, for: userId)
        }
    }
    
    // --- BNPL Calculation Logic (remains the same) ---
    func calculateSchedulePreview(for plan: BNPLPlan) -> BNPLSchedulePreview? {
        guard let amount = Double(amountStr), amount > 0 else { return nil }

        let fee = calculateFee(for: plan, amount: amount)
        let totalDebt = amount + fee
        
        let initialPaymentPercent = (plan.initialPaymentPercent ?? 0) / 100.0
        let initialPayment = totalDebt * initialPaymentPercent
        
        let remainingBalance = totalDebt - initialPayment
        
        guard plan.installments > 0 else { return nil }
        let installmentAmount = remainingBalance / Double(plan.installments)
        
        var paymentDates = [Date]()
        var currentDate = date
        
        for _ in 0..<plan.installments {
            currentDate = calculateNextDueDate(from: currentDate, frequency: plan.paymentFrequency)
            paymentDates.append(currentDate)
        }
        
        let schedule = paymentDates.map { (date: $0, amount: installmentAmount) }
        
        return BNPLSchedulePreview(
            initialPayment: initialPayment,
            fee: fee,
            installmentAmount: installmentAmount,
            remainingBalance: remainingBalance,
            schedule: schedule
        )
    }
    
    private func calculateFee(for plan: BNPLPlan, amount: Double) -> Double {
        guard let feeValue = plan.feeValue else { return 0 }
        switch plan.feeType {
        case .none:
            return 0
        case .flat:
            return feeValue
        case .percentage:
            return amount * (feeValue / 100)
        }
    }
    
    private func calculateNextDueDate(from startDate: Date, frequency: PaymentFrequency) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate)!
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: startDate)!
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate)!
        }
    }
}
