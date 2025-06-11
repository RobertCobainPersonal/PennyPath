//
//  Account.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: This model has been simplified to remove nested details
//  and prepare for transaction-level BNPL plan application. The complex
//  `AccountDetails` enum has been replaced by a simple `AccountType` enum
//  and optional properties on the main struct.
//
//  UPDATED: Restored UK-centric naming and additional account types
//  based on user feedback.
//
//  FIXED: Re-added the `icon` computed property to the struct.
//

import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - AccountType Enum

/**
 * A simple enumeration to categorize the financial account type.
 * This replaces the previous complex, nested enum structure.
 *
 * UPDATED: Naming convention changed to UK standard (Current Account)
 * and Family Loan / Collection Account types have been re-added.
 */
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

    // Helper to provide a default icon for the account type
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
}


// MARK: - Main Account Struct

/**
 * The primary data model for a financial account in Firestore.
 * Conforms to Codable for easy Firestore integration and Identifiable for SwiftUI.
 */
struct Account: Codable, Identifiable {
    @DocumentID var id: String?
    
    // --- Core Fields ---
    var name: String
    var type: AccountType
    var institution: String
    var currency: String = "GBP"
    var currentBalance: Double
    var lastUpdated: Timestamp = Timestamp(date: Date())
    
    // --- Optional & Type-Specific Fields ---
    
    // General
    var openingBalance: Double?
    var openingBalanceDate: Timestamp?
    var alertThreshold: Double?
    
    // For BNPL accounts
    var isBNPL: Bool?
    var outstandingBalance: Double?
    var linkedAccountId: String? // Default source for repayments
    
    // For Credit Cards
    var creditLimit: Double?
    var paymentDueDate: Timestamp?
    var apr: Double?
    
    // For Loans
    var originalAmount: Double?
    var interestRate: Double?
    var originationDate: Timestamp?
    
    // For Family/Friend Loans
    var counterparty: String?
    
    // For Collection Accounts
    var originalCreditor: String?
    var settlementAmount: Double?

    // --- Computed Properties for UI ---
    
    // Provides a consistent icon based on the account's type.
    // This delegates the call to the icon property on the AccountType enum.
    var icon: (name: String, color: Color) {
        return type.icon
    }
}
