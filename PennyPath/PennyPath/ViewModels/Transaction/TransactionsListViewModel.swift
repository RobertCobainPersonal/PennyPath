//
//  TransactionsListViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 17/06/2025.
//


//
//  TransactionsListViewModel.swift
//  PennyPath
//
//  Created by Senior iOS Developer on 17/06/2025.
//

import Foundation
import Combine

/// ViewModel for the Transactions List screen
/// Manages filtering, searching, and grouping of transactions
class TransactionsListViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let appStore: AppStore
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var filteredTransactions: [Transaction] = []
    @Published var groupedTransactions: [Date: [Transaction]] = [:]
    @Published var totalCount: Int = 0
    @Published var totalAmount: Double = 0.0
    @Published var incomeTotal: Double = 0.0
    @Published var expenseTotal: Double = 0.0
    
    // MARK: - Filter State
    private var currentSearchText: String = ""
    private var currentAccountFilter: String?
    private var currentCategoryFilter: String?
    private var currentEventFilter: String?
    private var currentTypeFilter: TransactionTypeFilter = .all
    private var currentDateRange: DateRangeFilter = .thisMonth
    
    // MARK: - Initialization
    init(appStore: AppStore) {
        self.appStore = appStore
        setupBindings()
        applyFilters() // Initial filter application
    }
    
    // MARK: - Private Methods
    
    /// Set up Combine bindings to react to AppStore changes
    private func setupBindings() {
        // Listen to transaction changes and reapply filters
        appStore.$transactions
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Listen to account changes (might affect account-filtered transactions)
        appStore.$accounts
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Listen to category changes
        appStore.$categories
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Listen to event changes
        appStore.$events
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    /// Apply current filters to the transaction list
    private func applyFilters() {
        var filtered = appStore.transactions
        
        // Apply search text filter
        if !currentSearchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.description.localizedCaseInsensitiveContains(currentSearchText) ||
                // Also search account names
                (appStore.accounts.first(where: { $0.id == transaction.accountId })?.name.localizedCaseInsensitiveContains(currentSearchText) ?? false) ||
                // Also search category names
                (transaction.categoryId.flatMap { categoryId in
                    appStore.categories.first(where: { $0.id == categoryId })?.name.localizedCaseInsensitiveContains(currentSearchText)
                } ?? false)
            }
        }
        
        // Apply account filter
        if let accountId = currentAccountFilter {
            filtered = filtered.filter { $0.accountId == accountId }
        }
        
        // Apply category filter
        if let categoryId = currentCategoryFilter {
            filtered = filtered.filter { $0.categoryId == categoryId }
        }
        
        // Apply event filter
        if let eventId = currentEventFilter {
            filtered = filtered.filter { $0.eventId == eventId }
        }
        
        // Apply transaction type filter
        switch currentTypeFilter {
        case .all:
            break // No filter
        case .income:
            filtered = filtered.filter { $0.amount > 0 }
        case .expense:
            filtered = filtered.filter { $0.amount < 0 }
        case .transfer:
            // Transfers are identified by transactions with no category
            filtered = filtered.filter { $0.categoryId == nil }
        }
        
        // Apply date range filter
        let dateRange = currentDateRange.dateRange
        filtered = filtered.filter { dateRange.contains($0.date) }
        
        // Sort by date (newest first)
        filtered.sort { $0.date > $1.date }
        
        // Update published properties
        filteredTransactions = filtered
        groupedTransactions = groupTransactionsByDate(filtered)
        totalCount = filtered.count
        
        // Calculate totals
        totalAmount = filtered.reduce(0) { $0 + $1.amount }
        incomeTotal = filtered.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        expenseTotal = filtered.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
    }
    
    /// Group transactions by date for sectioned display
    private func groupTransactionsByDate(_ transactions: [Transaction]) -> [Date: [Transaction]] {
        let calendar = Calendar.current
        
        return Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
    }
    
    // MARK: - Public Methods
    
    /// Update filters with new values
    func updateFilters(
        searchText: String,
        accountId: String? = nil,
        categoryId: String? = nil,
        eventId: String? = nil,
        transactionType: TransactionTypeFilter = .all,
        dateRange: DateRangeFilter = .thisMonth
    ) {
        currentSearchText = searchText
        currentAccountFilter = accountId
        currentCategoryFilter = categoryId
        currentEventFilter = eventId
        currentTypeFilter = transactionType
        currentDateRange = dateRange
        
        applyFilters()
    }
    
    /// Clear all filters
    func clearFilters() {
        currentSearchText = ""
        currentAccountFilter = nil
        currentCategoryFilter = nil
        currentEventFilter = nil
        currentTypeFilter = .all
        currentDateRange = .thisMonth
        
        applyFilters()
    }
    
    /// Get summary statistics for current filtered set
    func getSummaryStats() -> TransactionSummaryStats {
        return TransactionSummaryStats(
            totalTransactions: totalCount,
            totalAmount: totalAmount,
            incomeAmount: incomeTotal,
            expenseAmount: expenseTotal,
            netAmount: incomeTotal - expenseTotal,
            averageTransaction: totalCount > 0 ? totalAmount / Double(totalCount) : 0,
            dateRange: currentDateRange
        )
    }
    
    /// Get transactions for a specific date (for drill-down views)
    func getTransactions(for date: Date) -> [Transaction] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        return filteredTransactions.filter { transaction in
            calendar.isDate(transaction.date, inSameDayAs: startOfDay)
        }.sorted { $0.date > $1.date }
    }
    
    /// Check if there are any active filters
    var hasActiveFilters: Bool {
        !currentSearchText.isEmpty ||
        currentAccountFilter != nil ||
        currentCategoryFilter != nil ||
        currentEventFilter != nil ||
        currentTypeFilter != .all ||
        currentDateRange != .thisMonth
    }
    
    /// Get a description of current active filters for UI display
    var activeFiltersDescription: String {
        var descriptions: [String] = []
        
        if !currentSearchText.isEmpty {
            descriptions.append("Search: \"\(currentSearchText)\"")
        }
        
        if let accountId = currentAccountFilter,
           let account = appStore.accounts.first(where: { $0.id == accountId }) {
            descriptions.append("Account: \(account.name)")
        }
        
        if let categoryId = currentCategoryFilter,
           let category = appStore.categories.first(where: { $0.id == categoryId }) {
            descriptions.append("Category: \(category.name)")
        }
        
        if let eventId = currentEventFilter,
           let event = appStore.events.first(where: { $0.id == eventId }) {
            descriptions.append("Event: \(event.name)")
        }
        
        if currentTypeFilter != .all {
            descriptions.append("Type: \(currentTypeFilter.displayName)")
        }
        
        if currentDateRange != .thisMonth {
            descriptions.append("Period: \(currentDateRange.displayName)")
        }
        
        return descriptions.joined(separator: " • ")
    }
}

// MARK: - Helper Models

/// Summary statistics for the current filtered transaction set
struct TransactionSummaryStats {
    let totalTransactions: Int
    let totalAmount: Double
    let incomeAmount: Double
    let expenseAmount: Double
    let netAmount: Double
    let averageTransaction: Double
    let dateRange: DateRangeFilter
    
    var formattedSummary: String {
        if totalTransactions == 0 {
            return "No transactions in \(dateRange.displayName.lowercased())"
        }
        
        let transactionText = totalTransactions == 1 ? "transaction" : "transactions"
        return "\(totalTransactions) \(transactionText) • Net: \(netAmount.formattedAsCurrency)"
    }
}