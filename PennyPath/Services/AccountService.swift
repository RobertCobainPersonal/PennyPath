//
//  AccountService.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//


//
//  AccountService.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class AccountService {
    
    static let shared = AccountService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// Saves a new account document to the user's collection in Firestore.
    /// - Parameter account: The Account object to be saved.
    /// - Throws: An error if the user is not authenticated or if the Firestore write fails.
    func saveAccount(_ account: Account) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            // In a real app, you'd define a more specific error type.
            throw NSError(domain: "AccountService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }
        
        let collectionPath = "users/\(userId)/accounts"
        
        // Use `addDocument(from:)` which leverages Codable to save the object.
        try db.collection(collectionPath).addDocument(from: account)
    }
}