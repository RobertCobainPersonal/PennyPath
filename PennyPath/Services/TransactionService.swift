//
//  TransactionService.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// 1. UPDATED: This struct now uses categoryId
struct TransactionDetails {
    let amount: Double
    let accountId: String
    let date: Date
    let description: String
    let categoryId: String? // Changed from category: String
    let isBNPL: Bool
    
    let bnplPlan: BNPLPlan?
    let bnplFundingAccountId: String?
    let bnplSchedule: BNPLSchedulePreview?
}

class TransactionService {
    
    static let shared = TransactionService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    func addTransaction(details: TransactionDetails, for userId: String) async throws {
        if details.isBNPL {
            try await saveBNPLTransaction(details: details, userId: userId)
        } else {
            try await saveStandardTransaction(details: details, userId: userId)
        }
    }
    
    func addTransfer(fromAccount: Account, toAccount: Account, amount: Double, date: Date, description: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let fromAccountId = fromAccount.id,
              let toAccountId = toAccount.id else {
            throw NSError(domain: "TransactionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid user or account data."])
        }
        
        let batch = db.batch()
        let transactionCollection = db.collection("users/\(userId)/transactions")
        
        // 2. UPDATED: Prepare the outflow transaction with categoryId
        let outflowTransaction = Transaction(
            accountId: fromAccountId,
            amount: -abs(amount),
            date: Timestamp(date: date),
            description: "Transfer to \(toAccount.name)",
            categoryId: nil // Transfers don't have a user-set category
        )
        try batch.setData(from: outflowTransaction, forDocument: transactionCollection.document())
        
        // 2. UPDATED: Prepare the inflow transaction with categoryId
        let inflowTransaction = Transaction(
            accountId: toAccountId,
            amount: abs(amount),
            date: Timestamp(date: date),
            description: "Transfer from \(fromAccount.name)",
            categoryId: nil // Transfers don't have a user-set category
        )
        try batch.setData(from: inflowTransaction, forDocument: transactionCollection.document())

        let sourceAccountRef = db.document("users/\(userId)/accounts/\(fromAccountId)")
        batch.updateData(["currentBalance": FieldValue.increment(-abs(amount))], forDocument: sourceAccountRef)
        
        let destinationAccountRef = db.document("users/\(userId)/accounts/\(toAccountId)")
        batch.updateData(["currentBalance": FieldValue.increment(abs(amount))], forDocument: destinationAccountRef)
        
        try await batch.commit()
    }
    
    // MARK: - Private Helper Methods
    
    private func saveStandardTransaction(details: TransactionDetails, userId: String) async throws {
        let batch = db.batch()
        let transactionCollection = db.collection("users/\(userId)/transactions")
        
        let sign = (details.amount >= 0) ? 1.0 : -1.0 // Sign should depend on income/expense, let's assume positive is income
        
        // 3. UPDATED: Use categoryId from details
        let newTransaction = Transaction(
            accountId: details.accountId,
            amount: abs(details.amount) * sign,
            date: Timestamp(date: details.date),
            description: details.description,
            categoryId: details.categoryId
        )
        
        try batch.setData(from: newTransaction, forDocument: transactionCollection.document())
        let accountRef = db.document("users/\(userId)/accounts/\(details.accountId)")
        batch.updateData(["currentBalance": FieldValue.increment(abs(details.amount) * sign)], forDocument: accountRef)
        
        try await batch.commit()
    }
    
    private func saveBNPLTransaction(details: TransactionDetails, userId: String) async throws {
        guard let plan = details.bnplPlan,
              let schedule = details.bnplSchedule,
              let fundingAccountId = details.bnplFundingAccountId else {
            throw NSError(domain: "TransactionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing BNPL data."])
        }

        let batch = db.batch()
        let transactionRef = db.collection("users/\(userId)/transactions").document()
        var scheduledPaymentIds = [String]()
        
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
        
        // 4. UPDATED: Use categoryId from details
        let newTransaction = Transaction(
            id: transactionRef.documentID,
            accountId: details.accountId,
            amount: details.amount,
            date: Timestamp(date: details.date),
            description: details.description,
            categoryId: details.categoryId,
            isBNPL: true,
            bnplPlanId: plan.id,
            initialPaymentAmount: schedule.initialPayment,
            feeAmount: schedule.fee,
            linkedAccountId: fundingAccountId,
            scheduledPaymentIds: scheduledPaymentIds
        )
        try batch.setData(from: newTransaction, forDocument: transactionRef)
        
        let fundingAccountRef = db.document("users/\(userId)/accounts/\(fundingAccountId)")
        batch.updateData(["currentBalance": FieldValue.increment(-schedule.initialPayment)], forDocument: fundingAccountRef)
        
        let bnplAccountRef = db.document("users/\(userId)/accounts/\(details.accountId)")
        batch.updateData(["currentBalance": FieldValue.increment(details.amount)], forDocument: bnplAccountRef)
        
        try await batch.commit()
    }
}
