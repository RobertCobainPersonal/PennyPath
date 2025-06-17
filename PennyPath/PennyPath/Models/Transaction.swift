//
//  Transaction.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import Foundation
import FirebaseFirestore

/// Unified transaction model for all financial events (past and future)
struct Transaction: Identifiable, Codable {
    let id: String
    let userId: String
    let accountId: String
    let categoryId: String?
    let bnplPlanId: String? // Link to BNPL plan for installment payments
    let eventId: String? // Link to Event for grouping transactions
    let amount: Double // Positive for income, negative for expenses
    let description: String
    var date: Date
    var isScheduled: Bool
    var isPaid: Bool
    let recurrence: RecurrenceType?
    let createdAt: Date
    
    // FIXED: Added eventId parameter to initializer
    init(id: String = UUID().uuidString, userId: String, accountId: String,
         categoryId: String? = nil, bnplPlanId: String? = nil, eventId: String? = nil,
         amount: Double, description: String, date: Date = Date(),
         isScheduled: Bool = false, recurrence: RecurrenceType? = nil) {
        self.id = id
        self.userId = userId
        self.accountId = accountId
        self.categoryId = categoryId
        self.bnplPlanId = bnplPlanId
        self.eventId = eventId  // FIXED: This was missing
        self.amount = amount
        self.description = description
        self.date = date
        self.isScheduled = isScheduled
        self.isPaid = false
        self.recurrence = recurrence
        self.createdAt = Date()
    }
    
    // MARK: - Firestore Integration
    
    /// Create Transaction from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let accountId = data["accountId"] as? String,
              let amount = data["amount"] as? Double,
              let description = data["description"] as? String,
              let date = (data["date"] as? Timestamp)?.dateValue(),
              let isScheduled = data["isScheduled"] as? Bool,
              let isPaid = data["isPaid"] as? Bool,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.accountId = accountId
        self.categoryId = data["categoryId"] as? String
        self.bnplPlanId = data["bnplPlanId"] as? String
        self.eventId = data["eventId"] as? String
        self.amount = amount
        self.description = description
        self.date = date
        self.isScheduled = isScheduled
        self.isPaid = isPaid
        self.recurrence = RecurrenceType(rawValue: data["recurrence"] as? String ?? "")
        self.createdAt = createdAt
    }
    
    /// Convert Transaction to Firestore data
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "accountId": accountId,
            "amount": amount,
            "description": description,
            "date": Timestamp(date: date),
            "isScheduled": isScheduled,
            "isPaid": isPaid,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let categoryId = categoryId {
            data["categoryId"] = categoryId
        }
        
        if let bnplPlanId = bnplPlanId {
            data["bnplPlanId"] = bnplPlanId
        }
        
        if let eventId = eventId {
            data["eventId"] = eventId
        }
        
        if let recurrence = recurrence {
            data["recurrence"] = recurrence.rawValue
        }
        
        return data
    }
}

/// Recurrence types for scheduled transactions
enum RecurrenceType: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    /// Calculate next occurrence date
    func nextDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}
