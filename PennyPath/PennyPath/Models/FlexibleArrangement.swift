//
//  FlexibleArrangement.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//


import Foundation
import FirebaseFirestore

/// Flexible arrangement model for family/friend loans and debt collection accounts
/// Handles informal agreements with variable payment amounts and schedules
struct FlexibleArrangement: Identifiable, Codable {
    let id: String
    let userId: String
    let accountId: String
    let type: ArrangementType
    let originalAmount: Double
    let description: String
    let startDate: Date
    var targetCompletionDate: Date?
    var minimumPayment: Double?
    var suggestedPayment: Double?
    var notes: String
    var isActive: Bool
    let createdAt: Date
    
    // Family/Friend specific fields
    var relationshipType: RelationshipType?
    var contactName: String?
    var contactPhone: String?
    
    // Debt Collection specific fields
    var originalCreditor: String?
    var collectionAgency: String?
    var referenceNumber: String?
    var settlementAmount: Double?
    
    init(id: String = UUID().uuidString, userId: String, accountId: String,
         type: ArrangementType, originalAmount: Double, description: String,
         startDate: Date = Date(), targetCompletionDate: Date? = nil,
         minimumPayment: Double? = nil, suggestedPayment: Double? = nil,
         notes: String = "", relationshipType: RelationshipType? = nil,
         contactName: String? = nil, contactPhone: String? = nil,
         originalCreditor: String? = nil, collectionAgency: String? = nil,
         referenceNumber: String? = nil, settlementAmount: Double? = nil) {
        self.id = id
        self.userId = userId
        self.accountId = accountId
        self.type = type
        self.originalAmount = originalAmount
        self.description = description
        self.startDate = startDate
        self.targetCompletionDate = targetCompletionDate
        self.minimumPayment = minimumPayment
        self.suggestedPayment = suggestedPayment
        self.notes = notes
        self.relationshipType = relationshipType
        self.contactName = contactName
        self.contactPhone = contactPhone
        self.originalCreditor = originalCreditor
        self.collectionAgency = collectionAgency
        self.referenceNumber = referenceNumber
        self.settlementAmount = settlementAmount
        self.isActive = true
        self.createdAt = Date()
    }
    
    // MARK: - Firestore Integration
    
    /// Create FlexibleArrangement from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let accountId = data["accountId"] as? String,
              let typeRaw = data["type"] as? String,
              let type = ArrangementType(rawValue: typeRaw),
              let originalAmount = data["originalAmount"] as? Double,
              let description = data["description"] as? String,
              let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
              let notes = data["notes"] as? String,
              let isActive = data["isActive"] as? Bool,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.accountId = accountId
        self.type = type
        self.originalAmount = originalAmount
        self.description = description
        self.startDate = startDate
        self.targetCompletionDate = (data["targetCompletionDate"] as? Timestamp)?.dateValue()
        self.minimumPayment = data["minimumPayment"] as? Double
        self.suggestedPayment = data["suggestedPayment"] as? Double
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        
        // Optional fields
        self.relationshipType = RelationshipType(rawValue: data["relationshipType"] as? String ?? "")
        self.contactName = data["contactName"] as? String
        self.contactPhone = data["contactPhone"] as? String
        self.originalCreditor = data["originalCreditor"] as? String
        self.collectionAgency = data["collectionAgency"] as? String
        self.referenceNumber = data["referenceNumber"] as? String
        self.settlementAmount = data["settlementAmount"] as? Double
    }
    
    /// Convert FlexibleArrangement to Firestore data
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "accountId": accountId,
            "type": type.rawValue,
            "originalAmount": originalAmount,
            "description": description,
            "startDate": Timestamp(date: startDate),
            "notes": notes,
            "isActive": isActive,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        // Optional fields
        if let targetCompletionDate = targetCompletionDate {
            data["targetCompletionDate"] = Timestamp(date: targetCompletionDate)
        }
        if let minimumPayment = minimumPayment {
            data["minimumPayment"] = minimumPayment
        }
        if let suggestedPayment = suggestedPayment {
            data["suggestedPayment"] = suggestedPayment
        }
        if let relationshipType = relationshipType {
            data["relationshipType"] = relationshipType.rawValue
        }
        if let contactName = contactName {
            data["contactName"] = contactName
        }
        if let contactPhone = contactPhone {
            data["contactPhone"] = contactPhone
        }
        if let originalCreditor = originalCreditor {
            data["originalCreditor"] = originalCreditor
        }
        if let collectionAgency = collectionAgency {
            data["collectionAgency"] = collectionAgency
        }
        if let referenceNumber = referenceNumber {
            data["referenceNumber"] = referenceNumber
        }
        if let settlementAmount = settlementAmount {
            data["settlementAmount"] = settlementAmount
        }
        
        return data
    }
    
    // MARK: - Helper Methods
    
    /// Calculate total amount paid towards this arrangement
    func totalPaid(from transactions: [Transaction]) -> Double {
        return transactions
            .filter { $0.accountId == accountId && !$0.isScheduled }
            .reduce(0) { $0 + abs($1.amount) }
    }
    
    /// Calculate remaining balance
    func remainingBalance(from transactions: [Transaction]) -> Double {
        let paid = totalPaid(from: transactions)
        return abs(originalAmount) - paid
    }
    
    /// Calculate suggested overpayment amount if user can afford it
    func suggestedOverpayment(basedOnBudget availableAmount: Double) -> Double? {
        guard let minimum = minimumPayment, availableAmount > minimum else { return nil }
        
        let overpaymentAmount = availableAmount - minimum
        
        // Don't suggest overpayments less than £10
        return overpaymentAmount >= 10.0 ? overpaymentAmount : nil
    }
    
    /// Check if arrangement is overdue (missed minimum payments)
    func isOverdue(transactions: [Transaction]) -> Bool {
        guard let minimum = minimumPayment else { return false }
        
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let thisMonthPayments = transactions.filter { transaction in
            !transaction.isScheduled &&
            calendar.component(.month, from: transaction.date) == currentMonth &&
            calendar.component(.year, from: transaction.date) == currentYear
        }
        
        let thisMonthTotal = thisMonthPayments.reduce(0) { $0 + abs($1.amount) }
        return thisMonthTotal < minimum
    }
}

/// Type of flexible arrangement
enum ArrangementType: String, CaseIterable, Codable {
    case familyFriendLoan = "family_friend_loan"
    case debtCollection = "debt_collection"
    
    var displayName: String {
        switch self {
        case .familyFriendLoan: return "Family & Friends Loan"
        case .debtCollection: return "Debt Collection"
        }
    }
    
    var description: String {
        switch self {
        case .familyFriendLoan: return "Informal loan between family members or friends"
        case .debtCollection: return "Debt handed over to collection agency"
        }
    }
}

/// Relationship types for family/friend loans
enum RelationshipType: String, CaseIterable, Codable {
    case parent = "parent"
    case sibling = "sibling"
    case child = "child"
    case partner = "partner"
    case friend = "friend"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .parent: return "Parent"
        case .sibling: return "Sibling"
        case .child: return "Child"
        case .partner: return "Partner"
        case .friend: return "Friend"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .parent: return "person.crop.circle.badge.plus"
        case .sibling: return "person.2.crop.square.stack"
        case .child: return "person.crop.circle.badge.minus"
        case .partner: return "heart.circle"
        case .friend: return "person.crop.circle"
        case .other: return "person.crop.circle.dashed"
        }
    }
}