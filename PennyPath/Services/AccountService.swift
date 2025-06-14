//
//  AccountService.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//


//
//  AccountService.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class AccountService {
    
    static let shared = AccountService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// Saves a new account document to the user's collection in Firestore.
    /// - Parameter account: The Account object to be saved.
    /// - Throws: An error if the user is not authenticated or if the Firestore write fails.
    func saveAccount(_ account: Account) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            // In a real app, you'd define a more specific error type.
            throw NSError(domain: "AccountService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }
        
        let collectionPath = "users/\(userId)/accounts"
        
        // Use `addDocument(from:)` which leverages Codable to save the object.
        try db.collection(collectionPath).addDocument(from: account)
    }
    
    /// Deletes a specific account document from Firestore AND all of its associated
        /// transactions and scheduled payments in a single atomic batch, handling all
        /// primary and linked relationships (including BNPL).
        /// - Parameter accountId: The ID of the account document to delete.
        /// - Throws: An error if the user is not authenticated or if any part of the batch fails.
        func deleteAccount(withId accountId: String) async throws {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "AccountService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            }
            
            let batch = db.batch()
            let transactionsRef = db.collection("users/\(userId)/transactions")
            let scheduledPaymentsRef = db.collection("users/\(userId)/scheduled_payments")
            
            // --- Step 1: Find all related Transactions ---
            
            // Find transactions where the account is the primary account
            let primaryTransactionsQuery = transactionsRef.whereField("accountId", isEqualTo: accountId)
            
            // Find transactions where the account is the linked funding account (for BNPL)
            let linkedTransactionsQuery = transactionsRef.whereField("linkedAccountId", isEqualTo: accountId)
            
            let primaryTransactionDocs = try await primaryTransactionsQuery.getDocuments().documents
            let linkedTransactionDocs = try await linkedTransactionsQuery.getDocuments().documents
            
            // Combine them and get a unique set of transaction IDs to delete
            let allTransactionDocs = primaryTransactionDocs + linkedTransactionDocs
            let transactionIdsToDelete = Set(allTransactionDocs.map { $0.documentID })

            
            // --- Step 2: Find all related Scheduled Payments ---
            
            // Find scheduled payments where the account is the source of funds
            let sourcePaymentsQuery = scheduledPaymentsRef.whereField("sourceAccountId", isEqualTo: accountId)
            
            // Find scheduled payments whose parent transaction is being deleted
            let childPaymentsQuery = scheduledPaymentsRef.whereField("transactionId", in: Array(transactionIdsToDelete))

            let sourcePaymentDocs = try await sourcePaymentsQuery.getDocuments().documents
            // We only run the second query if there are transactions to delete, to avoid an error
            let childPaymentDocs = transactionIdsToDelete.isEmpty ? [] : try await childPaymentsQuery.getDocuments().documents
            
            let allPaymentDocs = sourcePaymentDocs + childPaymentDocs
            let paymentIdsToDelete = Set(allPaymentDocs.map { $0.documentID })

            // --- Step 3: Add all documents to the batch for deletion ---
            
            // Mark all unique transactions for deletion
            for docId in transactionIdsToDelete {
                batch.deleteDocument(transactionsRef.document(docId))
            }
            
            // Mark all unique scheduled payments for deletion
            for docId in paymentIdsToDelete {
                batch.deleteDocument(scheduledPaymentsRef.document(docId))
            }
            
            // Finally, mark the account itself for deletion
            let accountRef = db.collection("users/\(userId)/accounts").document(accountId)
            batch.deleteDocument(accountRef)
            
            // --- Step 4: Commit the entire atomic operation ---
            try await batch.commit()
        }
    
    /// Updates an existing account document in Firestore.
        /// - Parameter account: The Account object containing the updated data.
        /// - Throws: An error if the account ID is missing or the Firestore write fails.
        func updateAccount(_ account: Account) async throws {
            guard let accountId = account.id else {
                throw NSError(domain: "AccountService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Account ID not found for update."])
            }
            
            guard let userId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "AccountService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            }
            
            let documentPath = "users/\(userId)/accounts/\(accountId)"
            
            // Use setData(from:merge:) to update the document with the new data.
            // This will overwrite the existing document with the contents of the new 'account' object.
            try db.collection("users/\(userId)/accounts").document(accountId).setData(from: account, merge: true)
        }
}
