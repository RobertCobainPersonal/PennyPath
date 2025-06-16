//
//  DashboardViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//


import Foundation
import Combine

/// ViewModel for Dashboard screen
/// Manages dashboard-specific state and business logic
class DashboardViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let appStore: AppStore
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var netWorth: Double = 0.0
    @Published var currentMonthSpending: Double = 0.0
    @Published var upcomingPayments: [Transaction] = []
    @Published var budgetProgress: [BudgetProgressItem] = []
    
    // MARK: - Initialization
    init(appStore: AppStore) {
        self.appStore = appStore
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    /// Bind to AppStore changes using Combine
    private func setupBindings() {
        // Listen to net worth changes
        appStore.$accounts
            .map { accounts in
                accounts.reduce(0) { $0 + $1.balance }
            }
            .assign(to: &$netWorth)
        
        // Listen to spending changes
        appStore.$transactions
            .map { [weak self] transactions in
                self?.calculateCurrentMonthSpending(from: transactions) ?? 0.0
            }
            .assign(to: &$currentMonthSpending)
        
        // Listen to upcoming payments
        appStore.$transactions
            .map { [weak self] transactions in
                self?.getUpcomingPayments(from: transactions) ?? []
            }
            .assign(to: &$upcomingPayments)
        
        // Listen to budget progress
        Publishers.CombineLatest3(
            appStore.$budgets,
            appStore.$transactions,
            appStore.$categories
        )
        .map { [weak self] budgets, transactions, categories in
            self?.calculateBudgetProgress(budgets: budgets, transactions: transactions, categories: categories) ?? []
        }
        .assign(to: &$budgetProgress)
    }
    
    /// Calculate spending for current month
    private func calculateCurrentMonthSpending(from transactions: [Transaction]) -> Double {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return transactions
            .filter { !$0.isScheduled && $0.amount < 0 && $0.date >= startOfMonth }
            .reduce(0) { $0 + abs($1.amount) }
    }
    
    /// Get upcoming payments (next 30 days)
    private func getUpcomingPayments(from transactions: [Transaction]) -> [Transaction] {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return transactions
            .filter { $0.isScheduled && $0.date <= thirtyDaysFromNow }
            .sorted { $0.date < $1.date }
            .prefix(5) // Limit to 5 for dashboard
            .map { $0 }
    }
    
    /// Calculate budget progress for each category
    private func calculateBudgetProgress(budgets: [Budget], transactions: [Transaction], categories: [Category]) -> [BudgetProgressItem] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return budgets
            .filter { $0.month == currentMonth && $0.year == currentYear }
            .compactMap { budget in
                guard let category = categories.first(where: { $0.id == budget.categoryId }) else { return nil }
                
                let spent = transactions
                    .filter { transaction in
                        transaction.categoryId == budget.categoryId &&
                        !transaction.isScheduled &&
                        transaction.amount < 0 &&
                        Calendar.current.component(.month, from: transaction.date) == currentMonth &&
                        Calendar.current.component(.year, from: transaction.date) == currentYear
                    }
                    .reduce(0) { $0 + abs($1.amount) }
                
                return BudgetProgressItem(
                    categoryName: category.name,
                    budgetAmount: budget.amount,
                    spentAmount: spent,
                    categoryColor: category.color,
                    categoryIcon: category.icon
                )
            }
    }
}

// MARK: - Helper Models
struct BudgetProgressItem: Identifiable {
    let id = UUID()
    let categoryName: String
    let budgetAmount: Double
    let spentAmount: Double
    let categoryColor: String
    let categoryIcon: String
    
    var progressPercentage: Double {
        guard budgetAmount > 0 else { return 0 }
        return min(spentAmount / budgetAmount, 1.0)
    }
    
    var isOverBudget: Bool {
        spentAmount > budgetAmount
    }
    
    var remainingAmount: Double {
        max(budgetAmount - spentAmount, 0)
    }
}