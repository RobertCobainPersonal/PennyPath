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
    
    private var cancellables = Set<AnyCancellable>()
    
    func listenForData(store: AppStore) {
        // We listen to changes in budgets, transactions, and categories.
        // If any of them change, we recalculate our progress.
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
            // 1. Find the parent category for this budget.
            guard let parentCategory = categories.first(where: { $0.id == budget.categoryId }) else { continue }
            
            // 2. Create a list of all relevant category IDs: the parent's ID plus all of its children's IDs.
            let childCategoryIds = categories.filter { $0.parentCategoryId == parentCategory.id }.compactMap { $0.id }
            let allCategoryIds = [parentCategory.id].compactMap { $0 } + childCategoryIds

            // 3. Filter transactions where the categoryId is in our list of relevant IDs and the date is within the budget period.
            let relevantTransactions = transactions.filter { transaction in
                guard let transactionCategoryId = transaction.categoryId, allCategoryIds.contains(transactionCategoryId) else {
                    return false
                }
                
                let transactionDate = transaction.date.dateValue()
                let budgetStartDate = budget.startDate.dateValue()
                let budgetEndDate = budget.endDate.dateValue()
                
                return transactionDate >= budgetStartDate && transactionDate <= budgetEndDate
            }
            
            // 4. Sum the amounts of the relevant transactions (we only care about expenses)
            let spentAmount = relevantTransactions
                .filter { $0.amount < 0 }
                .reduce(0) { $0 + abs($1.amount) }
            
            // 5. Create the final progress object for the UI
            let progress = BudgetProgress(budget: budget, spentAmount: spentAmount, category: parentCategory)
            newProgressList.append(progress)
        }
        
        self.budgetProgressList = newProgressList.sorted { $0.category?.name ?? "" < $1.category?.name ?? "" }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
