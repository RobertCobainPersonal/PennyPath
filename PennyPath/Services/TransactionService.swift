//
//  TransactionService.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//
//  REFACTORED: This service no longer updates account balances directly.
//  Its sole responsibility is to write transaction documents to Firestore.
//  Balance calculation is now handled on the client side.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct TransactionDetails {
    let amount: Double
    let accountId: String
    let date: Date
    let description: String
    let categoryId: String?
    let isBNPL: Bool
    
    let bnplPlan: BNPLPlan?
    let bnplFundingAccountId: String?
    let bnplSchedule: BNPLSchedulePreview?
}

class TransactionService {
    
    static let shared = TransactionService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// The primary method to add a new transaction. It calls the appropriate private helper.
    func addTransaction(details: TransactionDetails, for userId: String) async throws {
        if details.isBNPL {
            try await saveBNPLTransaction(details: details, userId: userId)
        } else {
            try await saveStandardTransaction(details: details, userId: userId)
        }
    }
    
    /// Creates two transaction documents for a transfer between accounts.
    func addTransfer(fromAccount: Account, toAccount: Account, amount: Double, date: Date, description: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let fromAccountId = fromAccount.id,
              let toAccountId = toAccount.id else {
            throw NSError(domain: "TransactionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid user or account data."])
        }
        
        let batch = db.batch()
        let transactionCollection = db.collection("users/\(userId)/transactions")
        
        // Outflow transaction (negative amount)
        let outflowTransaction = Transaction(
            accountId: fromAccountId,
            amount: -abs(amount),
            date: Timestamp(date: date),
            description: "Transfer to \(toAccount.name)",
            categoryId: nil
        )
        try batch.setData(from: outflowTransaction, forDocument: transactionCollection.document())
        
        // Inflow transaction (positive amount)
        let inflowTransaction = Transaction(
            accountId: toAccountId,
            amount: abs(amount),
            date: Timestamp(date: date),
            description: "Transfer from \(fromAccount.name)",
            categoryId: nil
        )
        try batch.setData(from: inflowTransaction, forDocument: transactionCollection.document())
        
        // The service no longer updates balances.
        
        try await batch.commit()
    }

    // MARK: - Private Helper Methods
    
    private func saveStandardTransaction(details: TransactionDetails, userId: String) async throws {
        let transactionCollection = db.collection("users/\(userId)/transactions")
        
        // Income is positive, Expense is negative.
        let sign = (details.categoryId == nil && details.description.lowercased().contains("income")) ? 1.0 : -1.0
        
        let newTransaction = Transaction(
            accountId: details.accountId,
            amount: abs(details.amount) * sign,
            date: Timestamp(date: details.date), // Corrected: use details.date
            description: details.description,
            categoryId: details.categoryId
        )
        
        // Just save the transaction document. No balance update.
        try transactionCollection.addDocument(from: newTransaction)
    }
    
    private func saveBNPLTransaction(details: TransactionDetails, userId: String) async throws {
        guard let plan = details.bnplPlan,
              let schedule = details.bnplSchedule,
              let fundingAccountId = details.bnplFundingAccountId else {
            throw NSError(domain: "TransactionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing BNPL data."])
        }

        let batch = db.batch()
        let transactionCollection = db.collection("users/\(userId)/transactions")
        let transactionRef = transactionCollection.document()
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
        
        let newTransaction = Transaction(
            id: transactionRef.documentID,
            accountId: details.accountId,
            amount: details.amount,
            date: Timestamp(date: details.date), // Corrected: use details.date
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
        
        if schedule.initialPayment > 0 {
            let initialPaymentTransaction = Transaction(
                accountId: fundingAccountId,
                amount: -schedule.initialPayment,
                date: Timestamp(date: details.date), // Corrected: use details.date
                description: "Initial payment for \(details.description)",
                categoryId: details.categoryId
            )
            try batch.setData(from: initialPaymentTransaction, forDocument: transactionCollection.document())
        }
        
        try await batch.commit()
    }
    
    /// Deletes a transaction and any associated scheduled payments.
        /// - Parameter transactionId: The ID of the transaction to delete.
        /// - Throws: An error if the user is not authenticated or the batch delete fails.
        func deleteTransaction(withId transactionId: String) async throws {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "TransactionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            }
            
            let batch = db.batch()
            let transactionRef = db.collection("users/\(userId)/transactions").document(transactionId)
            
            // Get the transaction document to check for scheduled payments
            let transactionDoc = try await transactionRef.getDocument()
            let transaction = try transactionDoc.data(as: Transaction.self)
            
            // If it's a BNPL transaction with scheduled payments, delete them too
            if let scheduledPaymentIds = transaction.scheduledPaymentIds, !scheduledPaymentIds.isEmpty {
                for paymentId in scheduledPaymentIds {
                    let paymentRef = db.collection("users/\(userId)/scheduled_payments").document(paymentId)
                    batch.deleteDocument(paymentRef)
                }
            }
            
            // Delete the main transaction document
            batch.deleteDocument(transactionRef)
            
            // Commit the batch
            try await batch.commit()
        }
    
    func updateTransaction(_ transaction: Transaction) async throws {
        guard let transactionId = transaction.id else {
            throw NSError(domain: "TransactionService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Transaction ID not found for update."])
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "TransactionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }
        
        let docRef = db.collection("users/\(userId)/transactions").document(transactionId)
        
        // Use setData to overwrite the document with the updated version.
        try await docRef.setData(from: transaction)
    }
}
