//
//  ScheduledPayment.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import Foundation
import FirebaseFirestore

/// Defines the recurrence interval for a scheduled payment.
enum Recurrence: String, Codable, CaseIterable {
    case none = "None"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

/**
 * Represents a single, schedulable payment installment.
 *
 * These documents are created when a BNPL transaction is initiated or a recurring
 * payment is set up. They serve as the individual "to-do" items for future payments,
 * allowing the app to forecast cash flow and alert the user about upcoming debits.
 */
struct ScheduledPayment: Codable, Identifiable, Hashable {
    
    /// The document's unique identifier, automatically managed by Firestore.
    @DocumentID var id: String?
    
    /// A reference linking this installment back to its parent `Transaction`.
    var transactionId: String
    
    /// The account ID from which the payment will be drawn (e.g., the user's main current account).
    var sourceAccountId: String
    
    /// **NEW**: The destination account for transfer-type payments.
    var targetAccountId: String?
    
    /// The amount due for this specific installment.
    var amount: Double
    
    /// The date on which this payment is scheduled to be made.
    var dueDate: Timestamp
    
    /// A flag to track whether this installment has been paid. Defaults to `false`.
    var paid: Bool = false
    
    /// An optional timestamp that records when the payment was actually completed.
    var paymentDate: Timestamp?
    
    /// **NEW**: The recurrence rule for this payment, if any.
    var recurrence: Recurrence = .none
    
    // Conformance to Hashable for use in SwiftUI lists.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ScheduledPayment, rhs: ScheduledPayment) -> Bool {
        lhs.id == rhs.id
    }
}
