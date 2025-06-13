//
//  BudgetService.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//


//
//  BudgetService.swift
//  PennyPath
//
//  Created by Robert Cobain on 14/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class BudgetService {
    
    static let shared = BudgetService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// Saves a new Budget document to the user's collection in Firestore.
    func saveBudget(_ budget: Budget) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "BudgetService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }
        
        let collectionPath = "users/\(userId)/budgets"
        
        try db.collection(collectionPath).addDocument(from: budget)
    }
}