//
//  DashboardViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties for the View
    @Published var userName: String = "User"
    @Published var netWorth: Double = 0.0
    @Published var upcomingPayments: [ScheduledPayment] = []
    @Published var budgetSummary: [BudgetProgress] = []
    
    // A helper to quickly get account names for payments
    private var accountNameLookup = [String: String]()
    
    private var cancellables = Set<AnyCancellable>()
    private var firestoreListener: ListenerRegistration?

    init() {
        // We'll call the setup methods from the View's .onAppear
        // to ensure the store is ready.
    }

    /// This is the main setup method. It connects the ViewModel to the central AppStore
    /// and the AuthViewModel to start listening for data changes.
    func listenForData(store: AppStore, authViewModel: AuthViewModel) {
        
        // --- User Name ---
        // Get the user's name from the AuthViewModel
        authViewModel.$currentUser
            .compactMap { $0?.fullName }
            .assign(to: \.userName, on: self)
            .store(in: &cancellables)
        
        // --- Net Worth ---
        // Subscribe to the AppStore's calculated balances.
        // The `.map` operator calculates the sum, which is then assigned to our netWorth property.
        store.$calculatedBalances
            .map { $0.values.reduce(0, +) }
            .assign(to: \.netWorth, on: self)
            .store(in: &cancellables)
            
        // --- Budget Progress ---
        // This is the same logic as in the BudgetListViewModel.
        // It combines multiple data streams from the store to calculate progress.
        Publishers.CombineLatest3(store.$budgets, store.$transactions, store.$categories)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .map { (budgets, transactions, categories) -> [BudgetProgress] in
                self.calculateBudgetProgress(budgets: budgets, transactions: transactions, categories: categories)
            }
            .assign(to: \.budgetSummary, on: self)
            .store(in: &cancellables)
            
        // --- Upcoming Payments ---
        // We need to fetch these directly as they aren't part of the core AppStore data.
        // First, we'll create a lookup for account names.
        store.$accounts
            .map { accounts in
                Dictionary(uniqueKeysWithValues: accounts.map { ($0.id ?? "", $0.name) })
            }
            .assign(to: \.accountNameLookup, on: self)
            .store(in: &cancellables)
            
        // Now, fetch the payments from Firestore.
        fetchUpcomingPayments()
    }
    
    private func fetchUpcomingPayments() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove any existing listener to avoid duplicates
        firestoreListener?.remove()
        
        let paymentsPath = "users/\(userId)/scheduled_payments"
        let today = Timestamp(date: Calendar.current.startOfDay(for: Date()))
        
        // Query for the next 5 unpaid payments due today or later.
        self.firestoreListener = Firestore.firestore().collection(paymentsPath)
            .whereField("paid", isEqualTo: false)
            .whereField("dueDate", isGreaterThanOrEqualTo: today)
            .order(by: "dueDate", descending: false)
            .limit(to: 5)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching upcoming payments: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.upcomingPayments = documents.compactMap { try? $0.data(as: ScheduledPayment.self) }
            }
    }
    
    // This helper function is identical to the one in BudgetListViewModel
    private func calculateBudgetProgress(budgets: [Budget], transactions: [Transaction], categories: [Category]) -> [BudgetProgress] {
        var newProgressList = [BudgetProgress]()
        
        for budget in budgets {
            guard let parentCategory = categories.first(where: { $0.id == budget.categoryId }) else { continue }
            let childCategoryIds = categories.filter { $0.parentCategoryId == parentCategory.id }.compactMap { $0.id }
            let allCategoryIds = [parentCategory.id].compactMap { $0 } + childCategoryIds

            let relevantTransactions = transactions.filter { transaction in
                guard let transactionCategoryId = transaction.categoryId, allCategoryIds.contains(transactionCategoryId) else { return false }
                let transactionDate = transaction.date.dateValue()
                return transactionDate >= budget.startDate.dateValue() && transactionDate <= budget.endDate.dateValue()
            }
            
            let spentAmount = relevantTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
            let progress = BudgetProgress(budget: budget, spentAmount: spentAmount, category: parentCategory)
            newProgressList.append(progress)
        }
        
        // Return only the top 3 budgets by progress
        return Array(newProgressList.sorted { $0.progress > $1.progress }.prefix(3))
    }
    
    // Clean up listeners when the ViewModel is deallocated
    deinit {
        cancellables.forEach { $0.cancel() }
        firestoreListener?.remove()
        print("DashboardViewModel deinitialized.")
    }
}
