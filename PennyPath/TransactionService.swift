//
//  TransactionService.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// A struct to pass transaction data cleanly from a ViewModel to the Service.
struct TransactionDetails {
    let amount: Double
    let accountId: String
    let date: Date
    let description: String
    let category: String
    let isBNPL: Bool
    
    // Optional BNPL data
    let bnplPlan: BNPLPlan?
    let bnplFundingAccountId: String?
    let bnplSchedule: BNPLSchedulePreview?
}

class TransactionService {
    
    static let shared = TransactionService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// The primary method to add a new transaction to Firestore. It handles both standard and BNPL types.
    func addTransaction(details: TransactionDetails, for userId: String) async throws {
        if details.isBNPL {
            try await saveBNPLTransaction(details: details, userId: userId)
        } else {
            try await saveStandardTransaction(details: details, userId: userId)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Handles the simple case: a standard, one-off transaction.
    private func saveStandardTransaction(details: TransactionDetails, userId: String) async throws {
        let batch = db.batch()
        let transactionCollection = db.collection("users/\(userId)/transactions")
        
        let newTransaction = Transaction(
            accountId: details.accountId,
            amount: details.amount,
            date: Timestamp(date: details.date),
            category: details.category,
            description: details.description
        )
        
        // Add the transaction and update the account balance in one atomic operation.
        try batch.setData(from: newTransaction, forDocument: transactionCollection.document())
        let accountRef = db.document("users/\(userId)/accounts/\(details.accountId)")
        batch.updateData(["currentBalance": FieldValue.increment(-details.amount)], forDocument: accountRef)
        
        try await batch.commit()
    }
    
    /// Handles the complex BNPL case, creating multiple documents atomically as required by the PRD.
    private func saveBNPLTransaction(details: TransactionDetails, userId: String) async throws {
        guard let plan = details.bnplPlan,
              let schedule = details.bnplSchedule,
              let fundingAccountId = details.bnplFundingAccountId else {
            throw NSError(domain: "TransactionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing BNPL data."])
        }

        let batch = db.batch()
        let transactionRef = db.collection("users/\(userId)/transactions").document()
        var scheduledPaymentIds = [String]()
        
        // 1. Create all ScheduledPayment documents.
        for payment in schedule.schedule {
            let paymentRef = db.collection("users/\(userId)/scheduled_payments").document()
            let newScheduledPayment = ScheduledPayment(
                transactionId: transactionRef.documentID,
                sourceAccountId: fundingAccountId,
                amount: payment.amount,
                dueDate: Timestamp(date: payment.date)
            )
            try batch.setData(from: newScheduledPayment, forDocument: paymentRef)
            scheduledPaymentIds.append(paymentRef.documentID)
        }
        
        // 2. Create the master Transaction document.
        let newTransaction = Transaction(
            id: transactionRef.documentID,
            accountId: details.accountId,
            amount: details.amount,
            date: Timestamp(date: details.date),
            category: details.category,
            description: details.description,
            isBNPL: true,
            bnplPlanId: plan.id,
            initialPaymentAmount: schedule.initialPayment,
            feeAmount: schedule.fee,
            linkedAccountId: fundingAccountId,
            scheduledPaymentIds: scheduledPaymentIds
        )
        try batch.setData(from: newTransaction, forDocument: transactionRef)
        
        // 3. Update account balances.
        let fundingAccountRef = db.document("users/\(userId)/accounts/\(fundingAccountId)")
        batch.updateData(["currentBalance": FieldValue.increment(-schedule.initialPayment)], forDocument: fundingAccountRef)
        
        let bnplAccountRef = db.document("users/\(userId)/accounts/\(details.accountId)")
        batch.updateData(["outstandingBalance": FieldValue.increment(schedule.remainingBalance)], forDocument: bnplAccountRef)
        
        // 4. Commit all changes at once.
        try await batch.commit()
    }
}
