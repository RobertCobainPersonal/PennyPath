//
//  SpendingTrendsChart.swift (UPDATED - Bar Chart)
//  PennyPath
//
//  Created by Senior iOS Developer on 18/06/2025.
//  Updated: Replaced pie chart with bar chart for better spending comparison
//

import SwiftUI
import Charts

struct SpendingTrendsChart: View {
    let account: Account
    let transactions: [Transaction]
    let categories: [Category]
    
    @State private var timeframe: SpendingTimeframe = .thisMonth
    @State private var sortBy: SpendingSortType = .amount
    
    private var chartData: [CategorySpending] {
        generateCategorySpending()
    }
    
    private var uncategorizedSpending: CategorySpending? {
        generateUncategorizedSpending()
    }
    
    private var totalSpending: Double {
        chartData.reduce(0) { $0 + $1.amount } + (uncategorizedSpending?.amount ?? 0)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // REFINED: Minimal context line only
            contextDescription
            
            chartHeader
            
            // Uncategorized spending callout (if exists)
            if let uncategorized = uncategorizedSpending {
                uncategorizedCallout(uncategorized)
            }
            
            chartView
            chartControls
        }
    }
    
    // REFINED: Minimal context instead of redundant title
    private var contextDescription: some View {
        HStack {
            Text("Category breakdown and merchant analysis")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // REFINED: Lead with key metrics, eliminate redundant titles
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // PRIMARY METRIC: Number of categories
                Text("\(chartData.count) categories")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // CONTEXT: Timeframe
                Text(timeframe.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Total Spending")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(totalSpending.formattedAsCurrency)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var chartView: some View {
        Chart(chartData, id: \.id) { categorySpending in
            BarMark(
                x: .value("Category", categorySpending.name),
                y: .value("Amount", categorySpending.amount)
            )
            .foregroundStyle(Color(hex: categorySpending.color))
        }
        .frame(height: 260) // Increased for better readability
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let categoryName = value.as(String.self) {
                        Text(shortenCategoryName(categoryName))
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.quaternary)
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount.formattedAsCurrencyCompact)
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func uncategorizedCallout(_ uncategorized: CategorySpending) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Uncategorized Spending")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(uncategorized.amount.formattedAsCurrency) from \(uncategorized.transactionCount) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Categorize") {
                // TODO: Navigate to categorization flow
                print("Navigate to categorize transactions")
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var chartControls: some View {
        VStack(spacing: 20) {
            // Timeframe and sort controls
            HStack {
                // Timeframe selector
                Picker("Timeframe", selection: $timeframe) {
                    ForEach(SpendingTimeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
                
                // Sort selector
                Menu {
                    ForEach(SpendingSortType.allCases, id: \.self) { sortType in
                        Button(sortType.displayName) {
                            sortBy = sortType
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Sort")
                            .font(.subheadline)
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Category breakdown
            if !chartData.isEmpty {
                categoryBreakdown
            }
        }
    }
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Categories")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Show detailed breakdown
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Show top 4 categories
            ForEach(chartData.prefix(4)) { categorySpending in
                categoryRow(for: categorySpending)
            }
            
            // Summary for remaining categories
            if chartData.count > 4 {
                let remainingAmount = chartData.dropFirst(4).reduce(0) { $0 + $1.amount }
                let remainingCount = chartData.count - 4
                
                HStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    Text("\(remainingCount) other categories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(remainingAmount.formattedAsCurrency)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private func categoryRow(for categorySpending: CategorySpending) -> some View {
        let previousAmount = getPreviousPeriodAmount(for: categorySpending.id)
        let change = categorySpending.amount - previousAmount
        let showTrend = timeframe != .thisWeek && previousAmount > 0 && abs(change) > 10
        
        return HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: categorySpending.color))
                .frame(width: 16, height: 16)
            
            Text(categorySpending.name)
                .font(.body)
                .lineLimit(1)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(categorySpending.amount.formattedAsCurrency)
                    .font(.body)
                    .fontWeight(.semibold)
                
                if showTrend {
                    HStack(spacing: 3) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                            .foregroundColor(change >= 0 ? .red : .green)
                        
                        Text(abs(change).formattedAsCurrencyCompact)
                            .font(.caption2)
                            .foregroundColor(change >= 0 ? .red : .green)
                    }
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private func getPreviousPeriodAmount(for categoryId: String) -> Double {
        let previousRange = timeframe.previousPeriodRange
        
        let previousTransactions = transactions.filter { transaction in
            transaction.accountId == account.id &&
            transaction.amount < 0 &&
            !transaction.isScheduled &&
            transaction.categoryId == categoryId &&
            previousRange.contains(transaction.date)
        }
        
        return previousTransactions.reduce(0) { $0 + abs($1.amount) }
    }
    
    private func generateCategorySpending() -> [CategorySpending] {
        let dateRange = timeframe.dateRange
        
        // Filter transactions (EXCLUDING uncategorized)
        let relevantTransactions = transactions.filter { transaction in
            transaction.accountId == account.id &&
            transaction.amount < 0 &&
            !transaction.isScheduled &&
            transaction.categoryId != nil &&
            dateRange.contains(transaction.date)
        }
        
        // Group by category
        let categoryGroups = Dictionary(grouping: relevantTransactions) { transaction in
            transaction.categoryId!
        }
        
        // Calculate spending per category
        var categorySpending: [CategorySpending] = []
        
        for (categoryId, transactions) in categoryGroups {
            let totalAmount = transactions.reduce(0) { $0 + abs($1.amount) }
            
            if let category = categories.first(where: { $0.id == categoryId }) {
                categorySpending.append(CategorySpending(
                    id: categoryId,
                    name: category.name,
                    amount: totalAmount,
                    color: category.color,
                    transactionCount: transactions.count
                ))
            }
        }
        
        // Sort based on user preference
        let sorted = categorySpending.sorted { cat1, cat2 in
            switch sortBy {
            case .amount:
                return cat1.amount > cat2.amount
            case .name:
                return cat1.name < cat2.name
            case .frequency:
                return cat1.transactionCount > cat2.transactionCount
            }
        }
        
        return Array(sorted.prefix(6))
    }
    
    private func generateUncategorizedSpending() -> CategorySpending? {
        let dateRange = timeframe.dateRange
        
        let uncategorizedTransactions = transactions.filter { transaction in
            transaction.accountId == account.id &&
            transaction.amount < 0 &&
            !transaction.isScheduled &&
            transaction.categoryId == nil &&
            dateRange.contains(transaction.date)
        }
        
        guard !uncategorizedTransactions.isEmpty else { return nil }
        
        let totalAmount = uncategorizedTransactions.reduce(0) { $0 + abs($1.amount) }
        
        return CategorySpending(
            id: "uncategorized",
            name: "Uncategorized",
            amount: totalAmount,
            color: "#999999",
            transactionCount: uncategorizedTransactions.count
        )
    }
    
    private func shortenCategoryName(_ name: String) -> String {
        let shortNames: [String: String] = [
            "Food & Dining": "Food",
            "Bills & Utilities": "Bills",
            "Entertainment": "Fun",
            "Transport": "Travel",
            "Subscriptions": "Subs",
            "Shopping": "Shop"
        ]
        return shortNames[name] ?? name
    }
}

// MARK: - Supporting Types

struct CategorySpending: Identifiable {
    let id: String
    let name: String
    let amount: Double
    let color: String
    let transactionCount: Int
}

enum SpendingTimeframe: String, CaseIterable {
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case last3Months = "last3Months"
    
    var displayName: String {
        switch self {
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .last3Months: return "3 Months"
        }
    }
    
    var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return start...now
            
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return start...now
            
        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return start...now
        }
    }
    
    var previousPeriodRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisWeek:
            let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? now
            return previousWeekStart...thisWeekStart
            
        case .thisMonth:
            let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? now
            return previousMonthStart...thisMonthStart
            
        case .last3Months:
            let last3MonthsStart = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            let previous3MonthsStart = calendar.date(byAdding: .month, value: -3, to: last3MonthsStart) ?? now
            return previous3MonthsStart...last3MonthsStart
        }
    }
}

enum SpendingSortType: String, CaseIterable {
    case amount = "amount"
    case name = "name"
    case frequency = "frequency"
    
    var displayName: String {
        switch self {
        case .amount: return "By Amount"
        case .name: return "By Name"
        case .frequency: return "By Frequency"
        }
    }
}

// MARK: - Preview Provider
struct SpendingTrendsChart_Previews: PreviewProvider {
    static var previews: some View {
        let mockAccount = Account(
            userId: "test",
            name: "Test Account",
            type: .current,
            balance: 2500.0
        )
        
        let mockCategories = [
            Category(userId: "test", name: "Food", color: "#FF6B6B", icon: "fork.knife"),
            Category(userId: "test", name: "Transport", color: "#4ECDC4", icon: "car.fill"),
            Category(userId: "test", name: "Shopping", color: "#45B7D1", icon: "bag.fill"),
            Category(userId: "test", name: "Bills", color: "#96CEB4", icon: "bolt.fill"),
            Category(userId: "test", name: "Entertainment", color: "#FFEAA7", icon: "tv")
        ]
        
        let calendar = Calendar.current
        let now = Date()
        
        let mockTransactions = [
            // This month transactions
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[0].id, amount: -320.50, description: "Groceries", date: now),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[1].id, amount: -145.00, description: "Petrol", date: calendar.date(byAdding: .day, value: -5, to: now)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[2].id, amount: -609.99, description: "Clothes", date: calendar.date(byAdding: .day, value: -10, to: now)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[3].id, amount: -89.00, description: "Gas Bill", date: calendar.date(byAdding: .day, value: -15, to: now)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[4].id, amount: -101.50, description: "Cinema", date: calendar.date(byAdding: .day, value: -3, to: now)!),
            
            // Previous month for trend comparison
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[0].id, amount: -280.00, description: "Groceries", date: calendar.date(byAdding: .month, value: -1, to: now)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[1].id, amount: -120.00, description: "Petrol", date: calendar.date(byAdding: .month, value: -1, to: now)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[2].id, amount: -640.01, description: "Shopping", date: calendar.date(byAdding: .month, value: -1, to: now)!),
            
            // Uncategorized transactions
            Transaction(userId: "test", accountId: "test", categoryId: nil, amount: -100.00, description: "Unknown Store", date: calendar.date(byAdding: .day, value: -2, to: now)!)
        ]
        
        SpendingTrendsChart(
            account: mockAccount,
            transactions: mockTransactions,
            categories: mockCategories
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
