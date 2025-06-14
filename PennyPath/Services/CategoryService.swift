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
    
    func deleteCategory(withId categoryId: String) async throws {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "CategoryService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            }
            
            let batch = db.batch()
            let categoriesRef = db.collection("users/\(userId)/categories")
            let transactionsRef = db.collection("users/\(userId)/transactions")
            
            // --- Step 1: Find all child categories ---
            let subCategoryQuery = categoriesRef.whereField("parentCategoryId", isEqualTo: categoryId)
            let subCategoryDocs = try await subCategoryQuery.getDocuments().documents
            let subCategoryIds = subCategoryDocs.map { $0.documentID }
            
            // --- Step 2: Find all transactions linked to the category AND its children ---
            let allCategoryIdsToDelete = [categoryId] + subCategoryIds
            let transactionQuery = transactionsRef.whereField("categoryId", in: allCategoryIdsToDelete)
            let transactionDocsToUpdate = try await transactionQuery.getDocuments().documents
            
            // --- Step 3: Add operations to the batch ---
            
            // Mark all linked transactions to be updated (un-categorized)
            for doc in transactionDocsToUpdate {
                batch.updateData(["categoryId": NSNull()], forDocument: doc.reference)
            }
            
            // Mark all sub-categories for deletion
            for docId in subCategoryIds {
                batch.deleteDocument(categoriesRef.document(docId))
            }
            
            // Mark the main category for deletion
            batch.deleteDocument(categoriesRef.document(categoryId))
            
            // --- Step 4: Commit the batch ---
            try await batch.commit()
        }
}
