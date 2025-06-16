//
//  Account.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import Foundation
import FirebaseFirestore

/// Account model representing financial accounts
struct Account: Identifiable, Codable {
    let id: String
    let userId: String
    let name: String
    let type: AccountType
    var balance: Double
    let createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, name: String, type: AccountType, balance: Double = 0.0) {
        self.id = id
        self.userId = userId
        self.name = name
        self.type = type
        self.balance = balance
        self.createdAt = Date()
    }
    
    // MARK: - Firestore Integration
    
    /// Create Account from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let typeRawValue = data["type"] as? String,
              let type = AccountType(rawValue: typeRawValue),
              let balance = data["balance"] as? Double,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.name = name
        self.type = type
        self.balance = balance
        self.createdAt = createdAt
    }
    
    /// Convert Account to Firestore data
    func toFirestoreData() -> [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "type": type.rawValue,
            "balance": balance,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

/// Account types with display properties - UK terminology
enum AccountType: String, CaseIterable, Codable {
    case current = "current"
    case savings = "savings"
    case credit = "credit"
    case loan = "loan"
    case bnpl = "bnpl"
    case familyFriend = "family_friend"
    case debtCollection = "debt_collection"
    case prepaid = "prepaid"
    case investment = "investment"
    
    var displayName: String {
        switch self {
        case .current: return "Current Account"
        case .savings: return "Savings Account"
        case .credit: return "Credit Card"
        case .loan: return "Loan"
        case .bnpl: return "Buy Now Pay Later"
        case .familyFriend: return "Family & Friends"
        case .debtCollection: return "Debt Collection"
        case .prepaid: return "Prepaid/Cash Card"
        case .investment: return "Investment Account"
        }
    }
    
    var icon: String {
        switch self {
        case .current: return "banknote"
        case .savings: return "piggybank"
        case .credit: return "creditcard"
        case .loan: return "house"
        case .bnpl: return "calendar.badge.clock"
        case .familyFriend: return "person.2.fill"
        case .debtCollection: return "exclamationmark.triangle.fill"
        case .prepaid: return "creditcard.and.123"
        case .investment: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: String {
        switch self {
        case .current: return "#4ECDC4"
        case .savings: return "#96CEB4"
        case .credit: return "#FF6B6B"
        case .loan: return "#FFEAA7"
        case .bnpl: return "#E17055"
        case .familyFriend: return "#74B9FF"
        case .debtCollection: return "#FD79A8"
        case .prepaid: return "#00CEC9"
        case .investment: return "#6C5CE7"
        }
    }
    
    /// Whether this account type supports scheduled payments
    var supportsScheduledPayments: Bool {
        switch self {
        case .loan, .bnpl: return true
        case .current, .savings, .credit, .investment, .familyFriend, .debtCollection, .prepaid: return false
        }
    }
    
    /// Whether this account type affects credit score
    var affectsCreditScore: Bool {
        switch self {
        case .credit, .loan, .bnpl, .debtCollection: return true
        case .current, .savings, .investment, .familyFriend, .prepaid: return false
        }
    }
    
    /// Whether this account type supports flexible payment arrangements
    var supportsFlexiblePayments: Bool {
        switch self {
        case .familyFriend, .debtCollection: return true
        case .current, .savings, .credit, .loan, .bnpl, .investment, .prepaid: return false
        }
    }
    
    /// Whether this account type can have positive or negative balances
    var canHavePositiveBalance: Bool {
        switch self {
        case .familyFriend: return true // Can lend TO others
        case .current, .savings, .investment, .prepaid: return true
        case .credit, .loan, .bnpl, .debtCollection: return false
        }
    }
    
    /// Whether this account type is typically topped up from other accounts
    var isPrepaidType: Bool {
        switch self {
        case .prepaid: return true
        case .current, .savings, .credit, .loan, .bnpl, .familyFriend, .debtCollection, .investment: return false
        }
    }
    
    /// Typical use cases for this account type (for UI hints)
    var useCaseExamples: [String] {
        switch self {
        case .current: return ["Day-to-day banking", "Salary deposits", "Direct debits"]
        case .savings: return ["Emergency fund", "Holiday savings", "House deposit"]
        case .credit: return ["Monthly purchases", "Online shopping", "Emergency expenses"]
        case .loan: return ["Car finance", "Personal loan", "Mortgage"]
        case .bnpl: return ["Fashion purchases", "Electronics", "Home goods"]
        case .familyFriend: return ["House deposit help", "Emergency loan", "Family support"]
        case .debtCollection: return ["Old credit card debt", "Utility arrears", "Finance defaults"]
        case .prepaid: return ["Golf club bar card", "Work canteen", "Gym vending", "Costa card"]
        case .investment: return ["Stocks & shares", "Pension", "ISA"]
        }
    }
}
