//
//  User.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//


import Foundation
import FirebaseFirestore

/// User model for PennyPath app
struct User: Identifiable, Codable {
    let id: String
    let firstName: String
    let email: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString, firstName: String, email: String) {
        self.id = id
        self.firstName = firstName
        self.email = email
        self.createdAt = Date()
    }
    
    // MARK: - Firestore Integration
    
    /// Create User from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let firstName = data["firstName"] as? String,
              let email = data["email"] as? String,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.firstName = firstName
        self.email = email
        self.createdAt = createdAt
    }
    
    /// Convert User to Firestore data
    func toFirestoreData() -> [String: Any] {
        return [
            "firstName": firstName,
            "email": email,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}