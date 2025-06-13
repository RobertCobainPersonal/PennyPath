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

    var isFormValid: Bool {
        !(amountStr.isEmpty || selectedAccountId.isEmpty) &&
        (isBNPL ? !(selectedPlanId.isEmpty || selectedFundingAccountId.isEmpty) : true)
    }

    func save(plan: BNPLPlan?, schedule: BNPLSchedulePreview?) async throws {
            guard let userId = Auth.auth().currentUser?.uid, let amount = Double(amountStr) else {
                throw NSError(domain: "AddExpenseViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid data."])
            }

            // We no longer need to pass the category name here, as the ID is part of the transaction
            let details = TransactionDetails(
                amount: amount,
                accountId: selectedAccountId,
                date: date,
                description: description,
                // Pass the categoryId to be saved with the transaction
                categoryId: self.categoryId ?? "", // Passing ID to a field that expects a name. Let's fix TransactionDetails
                isBNPL: isBNPL,
                bnplPlan: plan,
                bnplFundingAccountId: selectedFundingAccountId,
                bnplSchedule: schedule
            )

            try await TransactionService.shared.addTransaction(details: details, for: userId)
        }
    
    // --- NEW METHOD TO CALCULATE THE BNPL SCHEDULE ---
    
    func calculateSchedulePreview(for plan: BNPLPlan) -> BNPLSchedulePreview? {
        guard let amount = Double(amountStr), amount > 0 else { return nil }

        let fee = calculateFee(for: plan, amount: amount)
        let totalDebt = amount + fee
        
        let initialPaymentPercent = (plan.initialPaymentPercent ?? 0) / 100.0
        let initialPayment = totalDebt * initialPaymentPercent
        
        let remainingBalance = totalDebt - initialPayment
        
        // Ensure we don't divide by zero if installments is 0
        guard plan.installments > 0 else { return nil }
        let installmentAmount = remainingBalance / Double(plan.installments)
        
        var paymentDates = [Date]()
        var currentDate = date
        
        // The schedule starts from the first payment *after* the initial one.
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
