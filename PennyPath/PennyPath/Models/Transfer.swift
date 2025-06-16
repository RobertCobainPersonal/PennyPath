//
//  Transfer.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//


import Foundation
import FirebaseFirestore

/// Transfer model for tracking money movement between user's own accounts
/// This is different from transactions as it's internal money movement, not income/expense
struct Transfer: Identifiable, Codable {
    let id: String
    let userId: String
    let fromAccountId: String
    let toAccountId: String
    let amount: Double // Always positive - represents amount transferred
    let description: String
    let date: Date
    let transferType: TransferType
    let createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, fromAccountId: String, 
         toAccountId: String, amount: Double, description: String, 
         date: Date = Date(), transferType: TransferType = .manual) {
        self.id = id
        self.userId = userId
        self.fromAccountId = fromAccountId
        self.toAccountId = toAccountId
        self.amount = amount
        self.description = description
        self.date = date
        self.transferType = transferType
        self.createdAt = Date()
    }
    
    // MARK: - Firestore Integration
    
    /// Create Transfer from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let fromAccountId = data["fromAccountId"] as? String,
              let toAccountId = data["toAccountId"] as? String,
              let amount = data["amount"] as? Double,
              let description = data["description"] as? String,
              let date = (data["date"] as? Timestamp)?.dateValue(),
              let transferTypeRaw = data["transferType"] as? String,
              let transferType = TransferType(rawValue: transferTypeRaw),
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.fromAccountId = fromAccountId
        self.toAccountId = toAccountId
        self.amount = amount
        self.description = description
        self.date = date
        self.transferType = transferType
        self.createdAt = createdAt
    }
    
    /// Convert Transfer to Firestore data
    func toFirestoreData() -> [String: Any] {
        return [
            "userId": userId,
            "fromAccountId": fromAccountId,
            "toAccountId": toAccountId,
            "amount": amount,
            "description": description,
            "date": Timestamp(date: date),
            "transferType": transferType.rawValue,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    // MARK: - Helper Methods
    
    /// Generate corresponding transactions for this transfer
    /// Returns two transactions: one negative (from account) and one positive (to account)
    func generateTransactions() -> (fromTransaction: Transaction, toTransaction: Transaction) {
        let fromTransaction = Transaction(
            id: "\(id)-from",
            userId: userId,
            accountId: fromAccountId,
            categoryId: nil,
            amount: -amount,
            description: "Transfer to \(description)",
            date: date
        )
        
        let toTransaction = Transaction(
            id: "\(id)-to",
            userId: userId,
            accountId: toAccountId,
            categoryId: nil,
            amount: amount,
            description: "Transfer from account",
            date: date
        )
        
        return (fromTransaction, toTransaction)
    }
}

/// Types of transfers between accounts
enum TransferType: String, CaseIterable, Codable {
    case manual = "manual"
    case topUp = "top_up"
    case payoff = "payoff"
    case savings = "savings"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual Transfer"
        case .topUp: return "Top Up"
        case .payoff: return "Payoff"
        case .savings: return "Savings Transfer"
        }
    }
    
    var description: String {
        switch self {
        case .manual: return "General transfer between accounts"
        case .topUp: return "Top up prepaid card or similar"
        case .payoff: return "Pay off credit card or loan"
        case .savings: return "Move money to savings"
        }
    }
    
    var icon: String {
        switch self {
        case .manual: return "arrow.left.arrow.right"
        case .topUp: return "plus.circle"
        case .payoff: return "minus.circle"
        case .savings: return "arrow.up.circle"
        }
    }
}