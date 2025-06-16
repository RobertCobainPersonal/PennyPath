//
//  Event.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import Foundation
import FirebaseFirestore

/// Event model for grouping transactions by specific occasions or projects
struct Event: Identifiable, Codable {
    let id: String
    let userId: String
    let name: String
    let description: String
    let startDate: Date?
    let endDate: Date?
    let color: String // Hex color code
    let icon: String // SF Symbol name
    let isActive: Bool
    let createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, name: String, 
         description: String = "", startDate: Date? = nil, endDate: Date? = nil,
         color: String = "#45B7D1", icon: String = "calendar", isActive: Bool = true) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.color = color
        self.icon = icon
        self.isActive = isActive
        self.createdAt = Date()
    }
    
    // MARK: - Firestore Integration
    
    /// Create Event from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let description = data["description"] as? String,
              let color = data["color"] as? String,
              let icon = data["icon"] as? String,
              let isActive = data["isActive"] as? Bool,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.name = name
        self.description = description
        self.startDate = (data["startDate"] as? Timestamp)?.dateValue()
        self.endDate = (data["endDate"] as? Timestamp)?.dateValue()
        self.color = color
        self.icon = icon
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    /// Convert Event to Firestore data
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "name": name,
            "description": description,
            "color": color,
            "icon": icon,
            "isActive": isActive,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let startDate = startDate {
            data["startDate"] = Timestamp(date: startDate)
        }
        if let endDate = endDate {
            data["endDate"] = Timestamp(date: endDate)
        }
        
        return data
    }
    
    // MARK: - Helper Properties
    
    /// Check if event is currently active (between start and end dates)
    var isCurrentlyActive: Bool {
        guard isActive else { return false }
        
        let now = Date()
        
        if let start = startDate, start > now {
            return false // Event hasn't started yet
        }
        
        if let end = endDate, end < now {
            return false // Event has ended
        }
        
        return true
    }
    
    /// Display name with date range if available
    var displayNameWithDates: String {
        guard let start = startDate else { return name }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        if let end = endDate {
            return "\(name) (\(formatter.string(from: start)) - \(formatter.string(from: end)))"
        } else {
            return "\(name) (from \(formatter.string(from: start)))"
        }
    }
}

// MARK: - Default Events
extension Event {
    /// Sample events for new users
    static func sampleEvents(for userId: String) -> [Event] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            Event(
                userId: userId,
                name: "Weekend in Paris",
                description: "Romantic getaway",
                startDate: calendar.date(byAdding: .day, value: -7, to: today),
                endDate: calendar.date(byAdding: .day, value: -5, to: today),
                color: "#FF6B6B",
                icon: "airplane",
                isActive: false
            ),
            Event(
                userId: userId,
                name: "Kitchen Renovation",
                description: "Home improvement project",
                startDate: calendar.date(byAdding: .month, value: -2, to: today),
                endDate: calendar.date(byAdding: .month, value: 1, to: today),
                color: "#4ECDC4",
                icon: "hammer"
            ),
            Event(
                userId: userId,
                name: "Golf Trip to Turkey",
                description: "Annual golf holiday with mates",
                startDate: calendar.date(byAdding: .month, value: 2, to: today),
                endDate: calendar.date(byAdding: .month, value: 2, to: today)?.addingTimeInterval(7 * 24 * 60 * 60),
                color: "#45B7D1",
                icon: "figure.golf"
            )
        ]
    }
}
