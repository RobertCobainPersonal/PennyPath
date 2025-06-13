//
//  Account.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: The model has been updated to use a fixed anchor balance.
//  The 'currentBalance' is no longer stored in Firestore and will be
//  calculated on the client side based on the anchor and transactions.
//

import Foundation
import FirebaseFirestore
import SwiftUI

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case currentAccount = "Current Account"
    case savings = "Savings Account"
    case creditCard = "Credit Card"
    case loan = "Loan"
    case bnpl = "BNPL"
    case familyLoan = "Family/Friend Loan"
    case collectionAccount = "Collection Account"
    case generic = "Generic Account"

    var id: String { self.rawValue }

    var icon: (name: String, color: Color) {
        switch self {
        case .currentAccount: return ("sterlingsign.circle.fill", .blue)
        case .savings: return ("banknote.fill", .green)
        case .creditCard: return ("creditcard.fill", .purple)
        case .loan: return ("doc.text.fill", .orange)
        case .bnpl: return ("tag.fill", .cyan)
        case .familyLoan: return ("person.2.fill", .pink)
        case .collectionAccount: return ("exclamationmark.triangle.fill", .red)
        case .generic: return ("questionmark.circle.fill", .gray)
        }
    }
    
    var isCredit: Bool {
        switch self {
        case .creditCard, .loan, .bnpl, .familyLoan, .collectionAccount:
            return true
        case .currentAccount, .savings, .generic:
            return false
        }
    }
}

struct Account: Codable, Identifiable {
    @DocumentID var id: String?
    
    // --- Core Fields ---
    var name: String
    var type: AccountType
    var institution: String
    var currency: String = "GBP"
    var lastUpdated: Timestamp = Timestamp(date: Date())
    
    // --- NEW: Anchor Balance System ---
    // The balance of the account at a specific, fixed point in time.
    var anchorBalance: Double
    // The date that the anchorBalance is valid for.
    var anchorDate: Timestamp
    
    // --- Optional & Type-Specific Fields ---
    var isBNPL: Bool?
    var linkedAccountId: String?
    
    var creditLimit: Double?
    var paymentDueDate: Timestamp?
    var apr: Double?
    
    var originalAmount: Double?
    var interestRate: Double?
    var originationDate: Timestamp?
    
    var counterparty: String?
    
    var originalCreditor: String?
    var settlementAmount: Double?
    
    // The 'currentBalance' is no longer a stored property.
    // It will be calculated in the app.

    // --- Computed Properties for UI ---
    var icon: (name: String, color: Color) {
        return type.icon
    }
}

