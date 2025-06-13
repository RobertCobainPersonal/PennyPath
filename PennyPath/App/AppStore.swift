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
    @Published var categories = [Category]()
    @Published var transactions = [Transaction]()
    @Published var budgets = [Budget]() // 1. New property for budgets
    
    private var db = Firestore.firestore()
    private var accountsListener: ListenerRegistration?
    private var plansListener: ListenerRegistration?
    private var categoriesListener: ListenerRegistration?
    private var transactionsListener: ListenerRegistration?
    private var budgetsListener: ListenerRegistration? // 2. New listener
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchAccounts(userId: user.uid)
                self?.fetchBNPLPlans(userId: user.uid)
                self?.fetchCategories(userId: user.uid)
                self?.fetchTransactions(userId: user.uid)
                self?.fetchBudgets(userId: user.uid) // Fetch budgets on login
            } else {
                self?.clearData()
            }
        }
    }
    
    func fetchAccounts(userId: String) {
        let collectionPath = "users/\(userId)/accounts"
        accountsListener?.remove()
        accountsListener = db.collection(collectionPath)
            .order(by: "lastUpdated", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                self.accounts = documents.compactMap { try? $0.data(as: Account.self) }
            }
    }
    
    func fetchBNPLPlans(userId: String) {
        let collectionPath = "users/\(userId)/bnpl_plans"
        plansListener?.remove()
        plansListener = db.collection(collectionPath)
            .order(by: "provider")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                self.bnplPlans = documents.compactMap { try? $0.data(as: BNPLPlan.self) }
            }
    }
    
    func fetchCategories(userId: String) {
        let collectionPath = "users/\(userId)/categories"
        categoriesListener?.remove()
        categoriesListener = db.collection(collectionPath)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                self.categories = documents.compactMap { try? $0.data(as: Category.self) }
            }
    }
    
    func fetchTransactions(userId: String) {
        let collectionPath = "users/\(userId)/transactions"
        transactionsListener?.remove()
        transactionsListener = db.collection(collectionPath)
            .order(by: "date", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                self.transactions = documents.compactMap { try? $0.data(as: Transaction.self) }
            }
    }
    
    // 3. --- NEW METHOD ---
    func fetchBudgets(userId: String) {
        let collectionPath = "users/\(userId)/budgets"
        budgetsListener?.remove()
        budgetsListener = db.collection(collectionPath)
            .addSnapshotListener { querySnapshot, error in
                 guard let documents = querySnapshot?.documents else { return }
                self.budgets = documents.compactMap { try? $0.data(as: Budget.self) }
            }
    }
    
    private func clearData() {
        accountsListener?.remove()
        plansListener?.remove()
        categoriesListener?.remove()
        transactionsListener?.remove()
        budgetsListener?.remove() // 4. Clear the new listener
        
        self.accounts.removeAll()
        self.bnplPlans.removeAll()
        self.categories.removeAll()
        self.transactions.removeAll()
        self.budgets.removeAll() // 4. Clear the new array
    }
}
