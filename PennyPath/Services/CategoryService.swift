//
//  CategoryService.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//


//
//  CategoryService.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class CategoryService {
    
    static let shared = CategoryService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// Saves a new Category document to the user's collection in Firestore.
    func saveCategory(_ category: Category) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "CategoryService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }
        
        let collectionPath = "users/\(userId)/categories"
        
        try db.collection(collectionPath).addDocument(from: category)
    }
}