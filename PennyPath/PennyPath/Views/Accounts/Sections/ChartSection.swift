//
//  ChartSection.swift
//  PennyPath
//
//  Created by Robert Cobain on 20/06/2025.
//


import SwiftUI

/// Chart section with type picker and clean chart display
/// Contains the refined UX improvements that eliminate redundant titles
struct ChartSection: View {
    @Binding var selectedChartType: ChartType
    let account: Account  // Changed from Account? to Account
    let viewModel: AccountDetailViewModel
    @ObservedObject var appStore: AppStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with chart type picker - no redundant titles
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text("Account Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Picker("Chart Type", selection: $selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.shortName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 220)
            }
            
            // Chart container - clean, no redundant headers
            CardView {
                VStack(spacing: 0) {
                    ChartContentView(
                        selectedChartType: selectedChartType,
                        account: account,
                        viewModel: viewModel,
                        appStore: appStore
                    )
                }
                .padding(.vertical, 4)
            }
        }
    }
}

/// Chart content switching view
/// Handles displaying the correct chart based on selected type
struct ChartContentView: View {
    let selectedChartType: ChartType
    let account: Account  // Changed from Account? to Account
    let viewModel: AccountDetailViewModel
    @ObservedObject var appStore: AppStore
    
    var body: some View {
        switch selectedChartType {
        case .balanceForecast:
            BalanceForecastChart(
                account: account,
                transactions: appStore.transactions.filter { $0.accountId == account.id },
                scheduledTransactions: viewModel.upcomingTransactions
            )
            
        case .spendingTrends:
            SpendingTrendsChart(
                account: account,
                transactions: appStore.transactions.filter { $0.accountId == account.id },
                categories: appStore.categories
            )
            
        case .paymentSchedule:
            PaymentScheduleChart(
                account: account,
                scheduledTransactions: viewModel.upcomingTransactions
            )
        }
    }
}

/// Error state for when chart data is unavailable
struct ChartErrorView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
                .font(.title2)
            
            Text("Unable to load chart")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Account data not available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minHeight: 200)
    }
}

// MARK: - Preview Provider
struct ChartSection_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppStore = AppStore()
        let mockAccount = Account(
            userId: "test",
            name: "Test Account",
            type: .current,
            balance: 2500.0
        )
        let mockViewModel = AccountDetailViewModel(appStore: mockAppStore, accountId: "test")
        
        @State var selectedType: ChartType = .balanceForecast
        
        ChartSection(
            selectedChartType: $selectedType,
            account: mockAccount,
            viewModel: mockViewModel,
            appStore: mockAppStore
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Chart Section")
    }
}
