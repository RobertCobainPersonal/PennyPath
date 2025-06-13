//
//  Transaction.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//


import Foundation
import FirebaseFirestore

/**
 * Represents a single financial transaction, either standard or a BNPL purchase.
 *
 * This model is designed to be the central record for any spending event. When a
 * "Buy Now, Pay Later" purchase is made, this single document captures the
* initial event, including the total amount, the fee, and references to the
 * resulting payment obligations.
 */
struct Transaction: Codable, Identifiable {
    
    @DocumentID var id: String?
    
    // MARK: - Core Transaction Fields
    
    var accountId: String
    var amount: Double
    var date: Timestamp
    var description: String
    var categoryId: String?
    
    // MARK: - BNPL-Specific Fields
    
    /// A flag to easily identify and filter for BNPL transactions.
    var isBNPL: Bool = false
    
    /// A reference to the user-defined BNPLPlan.
    /// Example: "plan_zilch_pay_in_6_weeks"
    var bnplPlanId: String?
    
    /// The amount of the upfront payment made at the time of purchase.
    var initialPaymentAmount: Double?
    
    /// The fee applied to the transaction, as defined by the BNPL plan.
    var feeAmount: Double?
    
    /// The funding account ID used for the initial payment and subsequent scheduled repayments.
    /// Example: "monzo_main_account_id"
    var linkedAccountId: String?
    
    /// An array of document IDs that point to the individual, scheduled payment
    /// documents created based on the BNPL plan's logic.
    var scheduledPaymentIds: [String]?
}
