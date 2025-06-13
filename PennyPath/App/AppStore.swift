//
//  AppStore.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AppStore: ObservableObject {
    
    @Published var accounts = [Account]()
    @Published var bnplPlans = [BNPLPlan]()
    @Published var categories = [Category]() // New property for categories
    
    private var db = Firestore.firestore()
    private var accountsListener: ListenerRegistration?
    private var plansListener: ListenerRegistration?
    private var categoriesListener: ListenerRegistration? // New listener
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchAccounts(userId: user.uid)
                self?.fetchBNPLPlans(userId: user.uid)
                self?.fetchCategories(userId: user.uid) // Fetch categories on login
            } else {
                self?.clearData()
            }
        }
    }
    
    // Fetches the user's accounts and listens for real-time changes.
    func fetchAccounts(userId: String) {
        let collectionPath = "users/\(userId)/accounts"
        accountsListener?.remove() // Avoid duplicate listeners
        accountsListener = db.collection(collectionPath)
            .order(by: "lastUpdated", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching accounts: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                // Update the central 'accounts' list. Any view watching this will automatically refresh.
                self.accounts = documents.compactMap { try? $0.data(as: Account.self) }
            }
    }
    
    // Fetches the user's BNPL plans and listens for real-time changes.
    func fetchBNPLPlans(userId: String) {
        let collectionPath = "users/\(userId)/bnpl_plans"
        plansListener?.remove() // Avoid duplicate listeners
        plansListener = db.collection(collectionPath)
            .order(by: "provider")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching BNPL plans: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                // Update the central 'bnplPlans' list.
                self.bnplPlans = documents.compactMap { try? $0.data(as: BNPLPlan.self) }
            }
    }
    
    func fetchCategories(userId: String) {
        let collectionPath = "users/\(userId)/categories"
        categoriesListener?.remove()
        categoriesListener = db.collection(collectionPath)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching categories: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self.categories = documents.compactMap { try? $0.data(as: Category.self) }
            }
    }
    
    private func clearData() {
        accountsListener?.remove()
        plansListener?.remove()
        categoriesListener?.remove() // Clear the new listener
        
        self.accounts.removeAll()
        self.bnplPlans.removeAll()
        self.categories.removeAll() // Clear the new array
    }
}
