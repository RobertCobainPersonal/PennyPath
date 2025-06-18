//
//  TransactionsListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 17/06/2025.
//

import SwiftUI

struct TransactionsListView: View {
    @EnvironmentObject var appStore: AppStore
    @StateObject private var viewModel: TransactionsListViewModel
    
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedAccountFilter: String = ""
    @State private var selectedCategoryFilter: String = ""
    @State private var selectedEventFilter: String = ""
    @State private var selectedTypeFilter: TransactionTypeFilter = .all
    @State private var selectedDateRange: DateRangeFilter = .thisMonth
    @State private var showingAddTransaction = false
    
    init(appStore: AppStore) {
        self._viewModel = StateObject(wrappedValue: TransactionsListViewModel(appStore: appStore))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter bar
                searchAndFilterBar
                
                // Active filters display
                if hasActiveFilters {
                    activeFiltersBar
                }
                
                // Transactions list or empty state
                transactionsList
            }
            .background(Color(.systemBackground)) // Clean white background instead of grouped
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .sheet(isPresented: $showingFilters) {
                TransactionFiltersSheet(
                    selectedAccount: $selectedAccountFilter,
                    selectedCategory: $selectedCategoryFilter,
                    selectedEvent: $selectedEventFilter,
                    selectedType: $selectedTypeFilter,
                    selectedDateRange: $selectedDateRange,
                    onReset: resetFilters
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search transactions...")
        .onChange(of: searchText) { _ in updateFilters() }
        .onChange(of: selectedAccountFilter) { _ in updateFilters() }
        .onChange(of: selectedCategoryFilter) { _ in updateFilters() }
        .onChange(of: selectedEventFilter) { _ in updateFilters() }
        .onChange(of: selectedTypeFilter) { _ in updateFilters() }
        .onChange(of: selectedDateRange) { _ in updateFilters() }
        .onAppear {
            // Hide the global FAB when this view appears - we have the + button in nav
            NotificationCenter.default.post(name: Notification.Name("HideGlobalFAB"), object: nil)
        }
        .onDisappear {
            // Show the global FAB when this view disappears
            NotificationCenter.default.post(name: Notification.Name("ShowGlobalFAB"), object: nil)
        }
    }
    
    // MARK: - Search and Filter Bar
    
    private var searchAndFilterBar: some View {
        HStack(spacing: 12) {
            // Filter button with badge
            Button(action: {
                showingFilters = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                    
                    Text("Filters")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if hasActiveFilters {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Quick date filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DateRangeFilter.allCases, id: \.self) { range in
                        quickDateFilterButton(range: range)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private func quickDateFilterButton(range: DateRangeFilter) -> some View {
        Button(action: {
            selectedDateRange = range
        }) {
            Text(range.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(selectedDateRange == range ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedDateRange == range ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Active Filters Bar
    
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !selectedAccountFilter.isEmpty,
                   let account = appStore.accounts.first(where: { $0.id == selectedAccountFilter }) {
                    filterChip(title: account.name, icon: "building.columns") {
                        selectedAccountFilter = ""
                    }
                }
                
                if !selectedCategoryFilter.isEmpty,
                   let category = appStore.categories.first(where: { $0.id == selectedCategoryFilter }) {
                    filterChip(title: category.name, icon: "tag") {
                        selectedCategoryFilter = ""
                    }
                }
                
                if !selectedEventFilter.isEmpty,
                   let event = appStore.events.first(where: { $0.id == selectedEventFilter }) {
                    filterChip(title: event.name, icon: "calendar") {
                        selectedEventFilter = ""
                    }
                }
                
                if selectedTypeFilter != .all {
                    filterChip(title: selectedTypeFilter.displayName, icon: "arrow.up.arrow.down") {
                        selectedTypeFilter = .all
                    }
                }
                
                // Clear all button
                Button("Clear All") {
                    resetFilters()
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    private func filterChip(title: String, icon: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            
            Text(title)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Transactions List
    
    private var transactionsList: some View {
        Group {
            if viewModel.filteredTransactions.isEmpty {
                transactionsEmptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                            transactionGroupSection(date: date, transactions: viewModel.groupedTransactions[date] ?? [])
                        }
                    }
                    .padding(.bottom, 80) // Reduced padding since no FAB
                }
            }
        }
    }
    
    private func transactionGroupSection(date: Date, transactions: [Transaction]) -> some View {
        VStack(spacing: 0) {
            // Date header with improved spacing
            HStack {
                Text(formatDateHeader(date))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                let dayTotal = transactions.reduce(0) { $0 + $1.amount }
                Text(dayTotal.formattedAsCurrency)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(dayTotal >= 0 ? .green : .red)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Transactions for this date - full width, no card wrapper
            VStack(spacing: 0) {
                ForEach(transactions) { transaction in
                    TransactionRowView(
                        transaction: transaction,
                        showAccount: true,
                        showEvent: true,
                        showDate: false, // Don't show date since grouped by date
                        onTap: {
                            // TODO: Navigate to transaction detail
                            print("Tapped transaction: \(transaction.description)")
                        }
                    )
                    
                    if transaction.id != transactions.last?.id {
                        Divider()
                            .padding(.leading, 64) // Align with text, not icon
                    }
                }
            }
            .background(Color(.systemBackground)) // Clean white background
            .padding(.bottom, 24) // Section spacing
        }
    }
    
    private var transactionsEmptyState: some View {
        VStack(spacing: 20) {
            if hasActiveFilters {
                // No results for current filters
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                
                Text("No transactions found")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Try adjusting your filters or search terms")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Clear Filters") {
                    resetFilters()
                }
                .foregroundColor(.blue)
            } else if !searchText.isEmpty {
                // No search results
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                
                Text("No matches for \"\(searchText)\"")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Check your spelling or try different keywords")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                // No transactions at all
                Image(systemName: "plus.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("No transactions yet")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Add your first transaction to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Add Transaction") {
                    showingAddTransaction = true
                }
                .foregroundColor(.blue)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private var hasActiveFilters: Bool {
        !selectedAccountFilter.isEmpty ||
        !selectedCategoryFilter.isEmpty ||
        !selectedEventFilter.isEmpty ||
        selectedTypeFilter != .all ||
        selectedDateRange != .thisMonth
    }
    
    private func resetFilters() {
        selectedAccountFilter = ""
        selectedCategoryFilter = ""
        selectedEventFilter = ""
        selectedTypeFilter = .all
        selectedDateRange = .thisMonth
        searchText = ""
    }
    
    private func updateFilters() {
        viewModel.updateFilters(
            searchText: searchText,
            accountId: selectedAccountFilter.isEmpty ? nil : selectedAccountFilter,
            categoryId: selectedCategoryFilter.isEmpty ? nil : selectedCategoryFilter,
            eventId: selectedEventFilter.isEmpty ? nil : selectedEventFilter,
            transactionType: selectedTypeFilter,
            dateRange: selectedDateRange
        )
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow" // Just "Tomorrow", no redundant "(tomorrow)"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else if date > Date() {
            // Future dates - add "in X days" context (but not for tomorrow)
            let daysFromNow = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateString = formatter.string(from: date)
            
            if daysFromNow <= 7 && daysFromNow > 1 {
                return "\(dateString) (in \(daysFromNow) days)"
            } else {
                return dateString
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Filter Types

enum TransactionTypeFilter: String, CaseIterable {
    case all = "all"
    case income = "income"
    case expense = "expense"
    case transfer = "transfer"
    
    var displayName: String {
        switch self {
        case .all: return "All Types"
        case .income: return "Income"
        case .expense: return "Expenses"
        case .transfer: return "Transfers"
        }
    }
}

enum DateRangeFilter: String, CaseIterable {
    case today = "today"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case lastMonth = "lastMonth"
    case last3Months = "last3Months"
    case thisYear = "thisYear"
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .last3Months: return "3 Months"
        case .thisYear: return "This Year"
        }
    }
    
    var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return start...end
            
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return start...end
            
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return start...end
            
        case .lastMonth:
            let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            return lastMonthStart...thisMonthStart
            
        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return start...now
            
        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return start...end
        }
    }
}

// MARK: - Preview Provider
struct TransactionsListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsListView(appStore: AppStore())
            .environmentObject(AppStore())
    }
}
