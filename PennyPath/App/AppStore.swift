//
//  AppStore.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//
//  REFACTORED: Now includes logic to calculate and publish live balances
//  for all accounts based on their anchor balance and transactions.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class AppStore: ObservableObject {
    
    // Published properties for raw data from Firestore
    @Published var accounts = [Account]()
    @Published var bnplPlans = [BNPLPlan]()
    @Published var categories = [Category]()
    @Published var transactions = [Transaction]()
    @Published var budgets = [Budget]()
    
    // --- NEW: A published dictionary to hold the calculated live balance for each account ---
    @Published var calculatedBalances: [String: Double] = [:]
    
    private var db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.setupListeners(for: user.uid)
                self?.setupBalanceCalculator()
            } else {
                self?.clearData()
            }
        }
    }
    
    private func setupListeners(for userId: String) {
        // Fetch all data types
        let accountsListener = db.collection("users/\(userId)/accounts").addSnapshotListener { snapshot, _ in
            self.accounts = snapshot?.documents.compactMap { try? $0.data(as: Account.self) } ?? []
        }
        let transactionsListener = db.collection("users/\(userId)/transactions").addSnapshotListener { snapshot, _ in
            self.transactions = snapshot?.documents.compactMap { try? $0.data(as: Transaction.self) } ?? []
        }
        let categoriesListener = db.collection("users/\(userId)/categories").addSnapshotListener { snapshot, _ in
            self.categories = snapshot?.documents.compactMap { try? $0.data(as: Category.self) } ?? []
        }
        // ... add listeners for other types like budgets, bnplPlans if needed
        
        self.listeners = [accountsListener, transactionsListener, categoriesListener]
    }
    
    // --- NEW: This method sets up a reactive calculator ---
    private func setupBalanceCalculator() {
        // This publisher will fire whenever the list of accounts OR the list of transactions changes.
        Publishers.CombineLatest($accounts, $transactions)
            .map { (accounts, transactions) -> [String: Double] in
                var balances = [String: Double]()
                
                for account in accounts {
                    guard let accountId = account.id else { continue }
                    
                    // 1. Get all transactions for this account that occurred AFTER its anchor date.
                    let relevantTransactions = transactions.filter {
                        $0.accountId == accountId && $0.date.dateValue() >= account.anchorDate.dateValue()
                    }
                    
                    // 2. Sum the amounts of these transactions.
                    let sumOfTransactions = relevantTransactions.reduce(0) { $0 + $1.amount }
                    
                    // 3. The current balance is the anchor balance plus the sum of subsequent transactions.
                    balances[accountId] = account.anchorBalance + sumOfTransactions
                }
                
                return balances
            }
            .assign(to: \.calculatedBalances, on: self)
            .store(in: &cancellables)
    }
    
    private func clearData() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        accounts.removeAll()
        transactions.removeAll()
        categories.removeAll()
        budgets.removeAll()
        bnplPlans.removeAll()
        calculatedBalances.removeAll()
    }
}
