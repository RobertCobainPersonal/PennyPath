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
    
    private var db = Firestore.firestore()
    private var accountsListener: ListenerRegistration?
    private var plansListener: ListenerRegistration?
    
    // The initializer is called when the AppStore is created.
    // It sets up a listener that watches for authentication changes.
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                // When a user logs in, fetch their data.
                self?.fetchAccounts(userId: user.uid)
                self?.fetchBNPLPlans(userId: user.uid)
            } else {
                // When a user logs out, clear all local data.
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
    
    // Stops listening to changes and clears the arrays, typically on logout.
    private func clearData() {
            accountsListener?.remove()
            plansListener?.remove()
            self.accounts.removeAll()
            self.bnplPlans.removeAll()
        }
}
