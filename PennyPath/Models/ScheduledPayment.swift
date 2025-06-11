//
//  ScheduledPayment.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//


import Foundation
import FirebaseFirestore


/**
 * Represents a single, schedulable payment installment.
 *
 * These documents are created when a BNPL transaction is initiated or a recurring
 * payment is set up. They serve as the individual "to-do" items for future payments,
 * allowing the app to forecast cash flow and alert the user about upcoming debits.
 */
struct ScheduledPayment: Codable, Identifiable {
    
    /// The document's unique identifier, automatically managed by Firestore.
    @DocumentID var id: String?
    
    /// A reference linking this installment back to its parent `Transaction`.
    /// This is crucial for tracing payments back to their origin (e.g., a specific ASOS purchase).
    var transactionId: String
    
    /// The account ID from which the payment will be drawn (e.g., the user's main current account).
    var sourceAccountId: String
    
    /// The amount due for this specific installment.
    var amount: Double
    
    /// The date on which this payment is scheduled to be made.
    var dueDate: Timestamp
    
    /// A flag to track whether this installment has been paid. Defaults to `false`.
    /// When a payment is confirmed, this is set to `true`.
    var paid: Bool = false
    
    /// An optional timestamp that records when the payment was actually completed.
    /// This can be set when the `paid` flag is updated to `true`.
    var paymentDate: Timestamp?
    
}
