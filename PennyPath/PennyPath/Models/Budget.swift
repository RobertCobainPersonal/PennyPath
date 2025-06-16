//
//  Budget.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//


import Foundation
import FirebaseFirestore

/// Budget model for tracking spending limits by category
struct Budget: Identifiable, Codable {
    let id: String
    let userId: String
    let categoryId: String
    let amount: Double
    let month: Int // 1-12
    let year: Int
    let createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, categoryId: String, amount: Double, 
         month: Int = Calendar.current.component(.month, from: Date()),
         year: Int = Calendar.current.component(.year, from: Date())) {
        self.id = id
        self.userId = userId
        self.categoryId = categoryId
        self.amount = amount
        self.month = month
        self.year = year
        self.createdAt = Date()
    }
    
    // MARK: - Firestore Integration
    
    /// Create Budget from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let categoryId = data["categoryId"] as? String,
              let amount = data["amount"] as? Double,
              let month = data["month"] as? Int,
              let year = data["year"] as? Int,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.categoryId = categoryId
        self.amount = amount
        self.month = month
        self.year = year
        self.createdAt = createdAt
    }
    
    /// Convert Budget to Firestore data
    func toFirestoreData() -> [String: Any] {
        return [
            "userId": userId,
            "categoryId": categoryId,
            "amount": amount,
            "month": month,
            "year": year,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    // MARK: - Helper Properties
    
    /// Check if this budget is for the current month
    var isCurrentMonth: Bool {
        let now = Date()
        let currentMonth = Calendar.current.component(.month, from: now)
        let currentYear = Calendar.current.component(.year, from: now)
        return month == currentMonth && year == currentYear
    }
    
    /// Get the date range this budget covers
    var dateRange: ClosedRange<Date>? {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month, day: 1)
        
        guard let startDate = calendar.date(from: components),
              let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else {
            return nil
        }
        
        return startDate...endDate
    }
    
    /// Display name for the budget period
    var periodDisplayName: String {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month)
        
        guard let date = calendar.date(from: components) else {
            return "Unknown Period"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}