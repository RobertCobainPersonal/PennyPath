//
//  BNPLPlan.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

import Foundation
import FirebaseFirestore

// Enum for the type of fee charged by the plan
enum FeeType: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case flat = "Flat Rate"
    case percentage = "Percentage"
    
    var id: String { self.rawValue }
}

// Enum for how often payments are scheduled
enum PaymentFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    
    var id: String { self.rawValue }
}


/**
 * Represents a reusable template for a "Buy Now, Pay Later" (BNPL) plan.
 * This model corresponds to the `bnpl_plans` collection in Firestore.
 */
struct BNPLPlan: Codable, Identifiable {
    @DocumentID var id: String?
    var provider: String
    var planName: String
    
    var feeType: FeeType
    var feeValue: Double? // Only applicable if feeType is not .none
    
    var installments: Int
    var paymentFrequency: PaymentFrequency
    
    // The percentage of the total amount to be paid upfront.
    var initialPaymentPercent: Double?
    
    // Optional: A default bank account to link payments to.
    var linkedAccountId: String?
    
    // Timestamp for when the plan was created or last updated.
    var lastUpdated: Timestamp = Timestamp(date: Date())
}
