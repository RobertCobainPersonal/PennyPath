//
//  DashboardView.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appStore: AppStore
    @StateObject private var viewModel: DashboardViewModel
    
    init(appStore: AppStore) {
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(appStore: appStore))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header with greeting
                    headerSection
                    
                    // Financial overview cards
                    overviewSection
                    
                    // Upcoming payments section
                    upcomingPaymentsSection
                    
                    // Budget progress section
                    budgetProgressSection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(greetingTime)!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(appStore.user?.firstName ?? "Welcome")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Profile picture placeholder
            Button(action: {
                // TODO: Profile action
            }) {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(appStore.user?.firstName.prefix(1) ?? "?")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(.top)
    }
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            // Net worth and spending in a row for tablets/larger screens
            HStack(spacing: 16) {
                NetWorthCard(netWorth: viewModel.netWorth)
                SpendingCard(currentMonthSpending: viewModel.currentMonthSpending)
            }
        }
    }
    
    private var upcomingPaymentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Upcoming Payments", icon: "calendar")
            
            if viewModel.upcomingPayments.isEmpty {
                emptyStateView(
                    icon: "checkmark.circle",
                    title: "All caught up!",
                    subtitle: "No upcoming payments in the next 30 days"
                )
            } else {
                CardView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.upcomingPayments) { transaction in
                            UpcomingPaymentRow(transaction: transaction)
                            
                            if transaction.id != viewModel.upcomingPayments.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var budgetProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Budget Progress", icon: "chart.bar")
            
            if viewModel.budgetProgress.isEmpty {
                emptyStateView(
                    icon: "plus.circle",
                    title: "No budgets set",
                    subtitle: "Create your first budget to track spending"
                )
            } else {
                CardView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.budgetProgress) { budgetItem in
                            BudgetProgressRow(budgetItem: budgetItem)
                            
                            if budgetItem.id != viewModel.budgetProgress.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        CardView {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var greetingTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<22: return "evening"
        default: return "evening"
        }
    }
}

// MARK: - Preview Provider
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(appStore: AppStore())
            .environmentObject(AppStore())
    }
}
