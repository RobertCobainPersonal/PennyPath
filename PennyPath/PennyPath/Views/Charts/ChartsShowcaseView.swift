//
//  ChartsShowcaseView.swift
//  PennyPath
//
//  Created by Robert Cobain on 19/06/2025.
//


import SwiftUI

struct ChartsShowcaseView: View {
    @State private var selectedChart: Int = 0
    
    // Mock data for testing
    private let mockAccount = Account(
        userId: "test",
        name: "Barclays Current Account",
        type: .current,
        balance: 2500.75
    )
    
    private let mockCategories = [
        Category(userId: "test", name: "Food & Dining", color: "#FF6B6B", icon: "fork.knife"),
        Category(userId: "test", name: "Transport", color: "#4ECDC4", icon: "car.fill"),
        Category(userId: "test", name: "Entertainment", color: "#45B7D1", icon: "tv"),
        Category(userId: "test", name: "Shopping", color: "#FFEAA7", icon: "bag.fill"),
        Category(userId: "test", name: "Bills & Utilities", color: "#96CEB4", icon: "bolt.fill")
    ]
    
    private var mockTransactions: [Transaction] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            // Recent spending for SpendingTrendsChart
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[0].id, amount: -125.40, description: "Tesco Weekly Shop", date: calendar.date(byAdding: .day, value: -2, to: today)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[1].id, amount: -65.00, description: "Shell Petrol", date: calendar.date(byAdding: .day, value: -3, to: today)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[2].id, amount: -12.50, description: "Vue Cinema", date: calendar.date(byAdding: .day, value: -5, to: today)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[3].id, amount: -89.99, description: "ASOS Clothes", date: calendar.date(byAdding: .weekOfYear, value: -1, to: today)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[4].id, amount: -156.00, description: "British Gas", date: calendar.date(byAdding: .weekOfYear, value: -2, to: today)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[0].id, amount: -45.80, description: "Pret A Manger", date: calendar.date(byAdding: .day, value: -7, to: today)!),
            Transaction(userId: "test", accountId: "test", categoryId: mockCategories[1].id, amount: -35.20, description: "Bus Pass", date: calendar.date(byAdding: .weekOfYear, value: -1, to: today)!)
        ]
    }
    
    private var mockScheduledTransactions: [Transaction] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            Transaction(userId: "test", accountId: "test", amount: -89.00, description: "British Gas Bill", date: calendar.date(byAdding: .day, value: 3, to: today)!, isScheduled: true, recurrence: .monthly),
            Transaction(userId: "test", accountId: "test", amount: -125.00, description: "Council Tax", date: calendar.date(byAdding: .day, value: 7, to: today)!, isScheduled: true, recurrence: .monthly),
            Transaction(userId: "test", accountId: "test", amount: -45.00, description: "BT Broadband", date: calendar.date(byAdding: .day, value: 12, to: today)!, isScheduled: true, recurrence: .monthly),
            Transaction(userId: "test", accountId: "test", amount: -320.50, description: "Car Finance", date: calendar.date(byAdding: .day, value: 15, to: today)!, isScheduled: true, recurrence: .monthly),
            Transaction(userId: "test", accountId: "test", amount: 2800.00, description: "Salary", date: calendar.date(byAdding: .day, value: 25, to: today)!, isScheduled: true, recurrence: .monthly)
        ]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Chart selector
                    Picker("Chart Type", selection: $selectedChart) {
                        Text("Balance Forecast").tag(0)
                        Text("Spending Trends").tag(1)
                        Text("Payment Schedule").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Chart display
                    chartView
                        .padding(.horizontal)
                    
                    // Chart info
                    chartInfoSection
                        .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Charts Showcase")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @ViewBuilder
    private var chartView: some View {
        CardView {
            Group {
                switch selectedChart {
                case 0:
                    BalanceForecastChart(
                        account: mockAccount,
                        transactions: mockTransactions,
                        scheduledTransactions: mockScheduledTransactions
                    )
                    
                case 1:
                    SpendingTrendsChart(
                        account: mockAccount,
                        transactions: mockTransactions,
                        categories: mockCategories
                    )
                    
                case 2:
                    PaymentScheduleChart(
                        account: mockAccount,
                        scheduledTransactions: mockScheduledTransactions
                    )
                    
                default:
                    Text("Unknown chart type")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var chartInfoSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    
                    Text("Chart Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Group {
                    switch selectedChart {
                    case 0:
                        balanceForecastInfo
                    case 1:
                        spendingTrendsInfo
                    case 2:
                        paymentScheduleInfo
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
    
    private var balanceForecastInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Balance Forecast Chart")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("• Shows 30-day balance projection based on scheduled transactions")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• Historical data (last 7 days) vs projected data (next 30 days)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• Interactive: Tap to see specific date balances")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• Toggle view between all data and projections only")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var spendingTrendsInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spending Trends Chart")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("• Pie chart showing spending breakdown by category")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• Timeframe selector: This Week, This Month, 3 Months")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• Interactive: Tap categories to highlight and see details")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• Shows percentage and amount for each category")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var paymentScheduleInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Schedule Chart")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("• Timeline and calendar views of upcoming payments")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• Color-coded by urgency: Red (overdue/today), Orange (soon), Blue (future)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• Interactive: Tap payments to see details")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• Shows payment amounts and due dates for next 30 days")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview Provider
struct ChartsShowcaseView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsShowcaseView()
    }
}
