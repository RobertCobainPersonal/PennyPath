//
//  SpendingTrendsChart.swift
//  PennyPath
//
//  Created by Robert Cobain on 19/06/2025.
//

import SwiftUI
import Charts

struct SpendingTrendsChart: View {
    let account: Account
    let transactions: [Transaction]
    let categories: [Category]
    
    @State private var selectedCategory: CategorySpending?
    @State private var timeframe: SpendingTimeframe = .thisMonth
    @State private var sortBy: SpendingSortType = .amount
    
    private var chartData: [CategorySpending] {
        generateCategorySpending()
    }
    
    private var totalSpending: Double {
        chartData.reduce(0) { $0 + $1.amount }
    }
    
    private var maxSpending: Double {
        chartData.map { $0.amount }.max() ?? 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            chartHeader
            chartView
            chartControls
        }
    }
    
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Spending by Category")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let selectedCategory = selectedCategory {
                    selectedCategoryInfo
                } else {
                    defaultMetrics
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Total Spending")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(totalSpending.formattedAsCurrency)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var selectedCategoryInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(selectedCategory?.amount.formattedAsCurrency ?? "")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: selectedCategory?.color ?? "#000000"))
            
            HStack(spacing: 4) {
                Text(selectedCategory?.name ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(selectedCategory?.transactionCount ?? 0) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var defaultMetrics: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(chartData.count) categories")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(timeframe.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var chartView: some View {
        Chart(chartData, id: \.id) { categorySpending in
            BarMark(
                x: .value("Category", categorySpending.name),
                y: .value("Amount", categorySpending.amount)
            )
            .foregroundStyle(Color(hex: categorySpending.color))
            .opacity(selectedCategory?.id == categorySpending.id ? 1.0 : 0.8)
            .cornerRadius(6)
        }
        .frame(height: 220) // Increased height for better readability
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
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleChartTap(at: location, in: geometry, with: chartProxy)
                    }
            }
        }
        .chartOverlay { chartProxy in
            if let selectedCategory = selectedCategory {
                GeometryReader { geometry in
                    let plotFrame = geometry[chartProxy.plotAreaFrame]
                    
                    if let categoryX = chartProxy.position(forX: selectedCategory.name) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: max(40, plotFrame.width / CGFloat(max(chartData.count, 1))))
                            .position(x: categoryX, y: plotFrame.midY)
                            .animation(.easeInOut(duration: 0.2), value: selectedCategory.name)
                    }
                }
            }
        }
        .padding(.horizontal, 8) // Add some breathing room
    }
    
    @ViewBuilder
    private func trendIndicator(for categorySpending: CategorySpending) -> some View {
        // Show trend comparison in the breakdown list instead of chart
        EmptyView()
    }
    
    private var chartControls: some View {
        VStack(spacing: 20) { // Increased spacing
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
                
                // Sort selector - more prominent
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
            
            // Simplified category breakdown - only top 4
            if !chartData.isEmpty {
                simplifiedCategoryBreakdown
            }
        }
    }
    
    private var simplifiedCategoryBreakdown: some View {
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
            
            // Show only top 4 categories for cleaner look
            ForEach(chartData.prefix(4)) { categorySpending in
                simplifiedCategoryRow(for: categorySpending)
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
    
    private func simplifiedCategoryRow(for categorySpending: CategorySpending) -> some View {
        let previousAmount = getPreviousPeriodAmount(for: categorySpending.id)
        let change = categorySpending.amount - previousAmount
        let showTrend = timeframe != .thisWeek && previousAmount > 0 && abs(change) > 10 // Only show significant changes
        
        return HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: categorySpending.color))
                .frame(width: 16, height: 16) // Slightly larger for better visibility
            
            Text(categorySpending.name)
                .font(.body) // Larger font for better readability
                .lineLimit(1)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(categorySpending.amount.formattedAsCurrency)
                    .font(.body) // Larger font
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
        .padding(.vertical, 12) // More vertical padding
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedCategory?.id == categorySpending.id ? Color.blue.opacity(0.1) : Color.clear)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = selectedCategory?.id == categorySpending.id ? nil : categorySpending
            }
        }
    }
    
    private func handleChartTap(at location: CGPoint, in geometry: GeometryProxy, with chartProxy: ChartProxy) {
        let plotFrame = geometry[chartProxy.plotAreaFrame]
        let relativeX = location.x - plotFrame.minX
        let plotWidth = plotFrame.width
        
        guard !chartData.isEmpty, plotWidth > 0 else { return }
        
        let categoryIndex = Int((relativeX / plotWidth) * Double(chartData.count))
        let clampedIndex = max(0, min(categoryIndex, chartData.count - 1))
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedCategory = selectedCategory?.id == chartData[clampedIndex].id ? nil : chartData[clampedIndex]
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func getPreviousPeriodAmount(for categoryId: String) -> Double {
        let calendar = Calendar.current
        let previousRange = timeframe.previousPeriodRange
        
        let previousTransactions = transactions.filter { transaction in
            transaction.accountId == account.id &&
            transaction.amount < 0 &&
            !transaction.isScheduled &&
            (transaction.categoryId == categoryId || (categoryId == "uncategorized" && transaction.categoryId == nil)) &&
            previousRange.contains(transaction.date)
        }
        
        return previousTransactions.reduce(0) { $0 + abs($1.amount) }
    }
    
    private func generateCategorySpending() -> [CategorySpending] {
        let dateRange = timeframe.dateRange
        
        // Filter transactions for this account and timeframe
        let relevantTransactions = transactions.filter { transaction in
            transaction.accountId == account.id &&
            transaction.amount < 0 && // Only expenses
            !transaction.isScheduled &&
            dateRange.contains(transaction.date)
        }
        
        // Group by category
        let categoryGroups = Dictionary(grouping: relevantTransactions) { transaction in
            transaction.categoryId ?? "uncategorized"
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
            } else {
                // Uncategorized spending
                categorySpending.append(CategorySpending(
                    id: "uncategorized",
                    name: "Uncategorized",
                    amount: totalAmount,
                    color: "#999999",
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
        
        // Limit to 6 categories max for cleaner chart
        return Array(sorted.prefix(6))
    }
    
    // Helper function to shorten category names for chart labels
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
        
        let mockTransactions = [
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[0].id, amount: -320.50, description: "Groceries"),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[1].id, amount: -145.00, description: "Petrol"),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[2].id, amount: -189.99, description: "Clothes"),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[3].id, amount: -89.00, description: "Gas Bill"),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[4].id, amount: -45.50, description: "Cinema")
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
