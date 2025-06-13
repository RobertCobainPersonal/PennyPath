//
//  Budget.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import Foundation
import FirebaseFirestore

/// Represents a user-defined budget for a specific spending category and time period.
struct Budget: Codable, Identifiable {
    
    @DocumentID var id: String?
    
    /// The ID of the Category this budget applies to.
    var categoryId: String
    
    /// The total amount allocated for this budget period.
    var amount: Double
    
    /// The start date for this budget period.
    var startDate: Timestamp
    
    /// The end date for this budget period.
    var endDate: Timestamp
}
