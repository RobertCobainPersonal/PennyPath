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
    
    // --- NEW METHOD FOR HANDLING TRANSFERS ---
    
    /// Atomically transfers an amount between two user-owned accounts.
    /// This creates two separate transaction records and updates both account balances in a single batch.
    /// - Throws: An error if the user is not authenticated or if the Firestore write fails.
    func addTransfer(fromAccount: Account, toAccount: Account, amount: Double, date: Date, description: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let fromAccountId = fromAccount.id, // Get ID from the account object
              let toAccountId = toAccount.id else {
            throw NSError(domain: "TransactionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid user or account data."])
        }
        
        let batch = db.batch()
        let transactionCollection = db.collection("users/\(userId)/transactions")
        
        let outflowTransaction = Transaction(
            accountId: fromAccountId,
            amount: -abs(amount),
            date: Timestamp(date: date),
            category: "Transfer",
            // CORRECTED: Use the account name in the description
            description: "Transfer to \(toAccount.name)"
        )
        try batch.setData(from: outflowTransaction, forDocument: transactionCollection.document())
        
        let inflowTransaction = Transaction(
            accountId: toAccountId,
            amount: abs(amount),
            date: Timestamp(date: date),
            category: "Transfer",
            // CORRECTED: Use the account name in the description
            description: "Transfer from \(fromAccount.name)"
        )
        try batch.setData(from: inflowTransaction, forDocument: transactionCollection.document())

        let sourceAccountRef = db.document("users/\(userId)/accounts/\(fromAccountId)")
        batch.updateData(["currentBalance": FieldValue.increment(-abs(amount))], forDocument: sourceAccountRef)
        
        let destinationAccountRef = db.document("users/\(userId)/accounts/\(toAccountId)")
        batch.updateData(["currentBalance": FieldValue.increment(abs(amount))], forDocument: destinationAccountRef)
        
        try await batch.commit()
    }
    
    // MARK: - Private Helper Methods
    
    /// Handles the simple case: a standard, one-off transaction.
    private func saveStandardTransaction(details: TransactionDetails, userId: String) async throws {
        let batch = db.batch()
        let transactionCollection = db.collection("users/\(userId)/transactions")
        
        // Ensure standard expenses are negative and income is positive
        let sign = details.category == "Income" ? 1.0 : -1.0
        
        let newTransaction = Transaction(
            accountId: details.accountId,
            amount: abs(details.amount) * sign,
            date: Timestamp(date: details.date),
            category: details.category,
            description: details.description
        )
        
        try batch.setData(from: newTransaction, forDocument: transactionCollection.document())
        let accountRef = db.document("users/\(userId)/accounts/\(details.accountId)")
        batch.updateData(["currentBalance": FieldValue.increment(abs(details.amount) * sign)], forDocument: accountRef)
        
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
            amount: details.amount, // BNPL is a credit, so it's a positive value on the BNPL account
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
        // The funding account pays the initial payment
        let fundingAccountRef = db.document("users/\(userId)/accounts/\(fundingAccountId)")
        batch.updateData(["currentBalance": FieldValue.increment(-schedule.initialPayment)], forDocument: fundingAccountRef)
        
        // The BNPL account's balance increases by the amount of the purchase
        let bnplAccountRef = db.document("users/\(userId)/accounts/\(details.accountId)")
        batch.updateData(["currentBalance": FieldValue.increment(details.amount)], forDocument: bnplAccountRef)
        
        try await batch.commit()
    }
}
