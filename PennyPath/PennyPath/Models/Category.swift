//
//  Category.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import Foundation
import FirebaseFirestore

/// Category model for organizing transactions
struct Category: Identifiable, Codable {
    let id: String
    let userId: String
    let name: String
    let parentId: String? // For hierarchical categories
    let color: String // Hex color code
    let icon: String // SF Symbol name
    let categoryType: CategoryType // NEW: Income vs Expense
    let createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, name: String, parentId: String? = nil,
         color: String, icon: String, categoryType: CategoryType = .expense) {
        self.id = id
        self.userId = userId
        self.name = name
        self.parentId = parentId
        self.color = color
        self.icon = icon
        self.categoryType = categoryType
        self.createdAt = Date()
    }
    
    // MARK: - Firestore Integration
    
    /// Create Category from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let color = data["color"] as? String,
              let icon = data["icon"] as? String,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.name = name
        self.parentId = data["parentId"] as? String
        self.color = color
        self.icon = icon
        self.categoryType = CategoryType(rawValue: data["categoryType"] as? String ?? "expense") ?? .expense
        self.createdAt = createdAt
    }
    
    /// Convert Category to Firestore data
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "name": name,
            "color": color,
            "icon": icon,
            "categoryType": categoryType.rawValue,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let parentId = parentId {
            data["parentId"] = parentId
        }
        
        return data
    }
    
    // MARK: - Helper Properties
    
    /// Check if this is a parent category
    var isParent: Bool {
        parentId == nil
    }
    
    /// Check if this is a subcategory
    var isSubcategory: Bool {
        parentId != nil
    }
}

// MARK: - Category Type

/// Category types for better organization
enum CategoryType: String, CaseIterable, Codable {
    case income = "income"
    case expense = "expense"
    case both = "both" // For transfers or flexible categories
    
    var displayName: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        case .both: return "General"
        }
    }
}

// MARK: - Default Categories
extension Category {
    /// Default categories for new users - UK focused with proper income/expense split
    static func defaultCategories(for userId: String) -> [Category] {
        return [
            // INCOME CATEGORIES
            Category(userId: userId, name: "Salary", color: "#6C5CE7", icon: "dollarsign.circle.fill", categoryType: .income),
            Category(userId: userId, name: "Freelance", color: "#00B894", icon: "briefcase.fill", categoryType: .income),
            Category(userId: userId, name: "Benefits", color: "#0984E3", icon: "hand.raised.fill", categoryType: .income),
            Category(userId: userId, name: "Investment Returns", color: "#00CEC9", icon: "chart.line.uptrend.xyaxis", categoryType: .income),
            Category(userId: userId, name: "Rental Income", color: "#A29BFE", icon: "house.fill", categoryType: .income),
            Category(userId: userId, name: "Gifts & Windfalls", color: "#FD79A8", icon: "gift.fill", categoryType: .income),
            Category(userId: userId, name: "Side Hustle", color: "#FDCB6E", icon: "star.fill", categoryType: .income),
            Category(userId: userId, name: "Cashback & Rewards", color: "#E17055", icon: "creditcard.fill", categoryType: .income),
            
            // EXPENSE CATEGORIES
            Category(userId: userId, name: "Food & Dining", color: "#FF6B6B", icon: "fork.knife", categoryType: .expense),
            Category(userId: userId, name: "Transport", color: "#4ECDC4", icon: "car.fill", categoryType: .expense),
            Category(userId: userId, name: "Entertainment", color: "#45B7D1", icon: "tv", categoryType: .expense),
            Category(userId: userId, name: "Bills & Utilities", color: "#96CEB4", icon: "bolt.fill", categoryType: .expense),
            Category(userId: userId, name: "Shopping", color: "#FFEAA7", icon: "bag.fill", categoryType: .expense),
            Category(userId: userId, name: "Healthcare & NHS", color: "#FD79A8", icon: "cross.fill", categoryType: .expense),
            Category(userId: userId, name: "Education", color: "#FDCB6E", icon: "book.fill", categoryType: .expense),
            Category(userId: userId, name: "Travel & Holidays", color: "#E17055", icon: "airplane", categoryType: .expense),
            Category(userId: userId, name: "Insurance", color: "#74B9FF", icon: "shield.fill", categoryType: .expense),
            Category(userId: userId, name: "Personal Care", color: "#A29BFE", icon: "heart.fill", categoryType: .expense),
            Category(userId: userId, name: "Council Tax", color: "#DDA0DD", icon: "building.2.fill", categoryType: .expense),
            Category(userId: userId, name: "Mortgage/Rent", color: "#CD853F", icon: "house.fill", categoryType: .expense),
            Category(userId: userId, name: "Subscriptions", color: "#81ECEC", icon: "rectangle.stack.fill", categoryType: .expense),
            Category(userId: userId, name: "Childcare", color: "#FAB1A0", icon: "figure.and.child.holdinghands", categoryType: .expense)
        ]
    }
}
