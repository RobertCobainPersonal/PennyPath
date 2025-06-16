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
    let createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, name: String, parentId: String? = nil,
         color: String, icon: String) {
        self.id = id
        self.userId = userId
        self.name = name
        self.parentId = parentId
        self.color = color
        self.icon = icon
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
        self.createdAt = createdAt
    }
    
    /// Convert Category to Firestore data
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "name": name,
            "color": color,
            "icon": icon,
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

// MARK: - Default Categories
extension Category {
    /// Default categories for new users - UK focused
    static func defaultCategories(for userId: String) -> [Category] {
        return [
            // Income categories
            Category(userId: userId, name: "Salary", color: "#6C5CE7", icon: "dollarsign.circle.fill"),
            Category(userId: userId, name: "Freelance", color: "#00B894", icon: "briefcase.fill"),
            Category(userId: userId, name: "Benefits", color: "#0984E3", icon: "hand.raised.fill"),
            Category(userId: userId, name: "Investment Returns", color: "#00CEC9", icon: "chart.line.uptrend.xyaxis"),
            Category(userId: userId, name: "Other Income", color: "#A29BFE", icon: "plus.circle.fill"),
            
            // Expense categories
            Category(userId: userId, name: "Food & Dining", color: "#FF6B6B", icon: "fork.knife"),
            Category(userId: userId, name: "Transport", color: "#4ECDC4", icon: "car.fill"),
            Category(userId: userId, name: "Entertainment", color: "#45B7D1", icon: "tv"),
            Category(userId: userId, name: "Bills & Utilities", color: "#96CEB4", icon: "bolt.fill"),
            Category(userId: userId, name: "Shopping", color: "#FFEAA7", icon: "bag.fill"),
            Category(userId: userId, name: "Healthcare & NHS", color: "#FD79A8", icon: "cross.fill"),
            Category(userId: userId, name: "Education", color: "#FDCB6E", icon: "book.fill"),
            Category(userId: userId, name: "Travel & Holidays", color: "#E17055", icon: "airplane"),
            Category(userId: userId, name: "Insurance", color: "#74B9FF", icon: "shield.fill"),
            Category(userId: userId, name: "Personal Care", color: "#A29BFE", icon: "heart.fill"),
            Category(userId: userId, name: "Council Tax", color: "#DDA0DD", icon: "building.2.fill"),
            Category(userId: userId, name: "Mortgage/Rent", color: "#CD853F", icon: "house.fill")
        ]
    }
}
