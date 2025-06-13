//
//  BudgetListViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 14/06/2025.
//

import Foundation
import FirebaseFirestore
import Combine

// A helper struct to combine a budget with its calculated progress for the UI
struct BudgetProgress: Identifiable {
    var id: String { budget.id ?? UUID().uuidString }
    let budget: Budget
    let spentAmount: Double
    let category: Category?
    
    var progress: Double {
        guard budget.amount > 0 else { return 0 }
        return spentAmount / budget.amount
    }
}

@MainActor
class BudgetListViewModel: ObservableObject {
    
    @Published var budgetProgressList = [BudgetProgress]()
    
    private var budgetsListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    func listenForData(store: AppStore) {
        // We need to listen to three things: budgets, transactions, and categories.
        // If any of them change, we need to recalculate our progress.
        Publishers.CombineLatest3(store.$budgets, store.$transactions, store.$categories)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main) // Avoid rapid recalculation
            .sink { [weak self] (budgets, transactions, categories) in
                self?.calculateBudgetProgress(budgets: budgets, transactions: transactions, categories: categories)
            }
            .store(in: &cancellables)
    }
    
    private func calculateBudgetProgress(budgets: [Budget], transactions: [Transaction], categories: [Category]) {
        var newProgressList = [BudgetProgress]()
        
        for budget in budgets {
            // Filter transactions that fall within the budget's date range and match its category
            let relevantTransactions = transactions.filter { transaction in
                guard transaction.categoryId == budget.categoryId else { return false }
                
                let transactionDate = transaction.date.dateValue()
                let budgetStartDate = budget.startDate.dateValue()
                let budgetEndDate = budget.endDate.dateValue()
                
                return transactionDate >= budgetStartDate && transactionDate <= budgetEndDate
            }
            
            // Sum the amounts of the relevant transactions (we only care about expenses)
            let spentAmount = relevantTransactions
                .filter { $0.amount < 0 } // Only sum expenses, not income
                .reduce(0) { $0 + abs($1.amount) }
            
            // Find the category object to get its name and icon
            let category = categories.first { $0.id == budget.categoryId }
            
            let progress = BudgetProgress(budget: budget, spentAmount: spentAmount, category: category)
            newProgressList.append(progress)
        }
        
        self.budgetProgressList = newProgressList.sorted { $0.category?.name ?? "" < $1.category?.name ?? "" }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
