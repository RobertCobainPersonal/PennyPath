//
//  DashboardView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//


//
//  DashboardView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import SwiftUI

struct DashboardView: View {
    
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // --- Header ---
                    headerView
                    
                    // --- Net Worth ---
                    netWorthCard
                    
                    // --- Upcoming Payments ---
                    upcomingPaymentsSection
                    
                    // --- Budget Summary ---
                    budgetSummarySection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                // This is the trigger that connects the ViewModel to the live data store.
                viewModel.listenForData(store: store, authViewModel: authViewModel)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(alignment: .leading) {
            Text("Good morning,")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(viewModel.userName)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }
    
    private var netWorthCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Net Worth")
                .font(.headline)
            Text(viewModel.netWorth, format: .currency(code: "GBP"))
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var upcomingPaymentsSection: some View {
        VStack(alignment: .leading) {
            Text("Upcoming Payments")
                .font(.title2)
                .fontWeight(.semibold)
            
            if viewModel.upcomingPayments.isEmpty {
                Text("You're all caught up!")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                VStack {
                    ForEach(viewModel.upcomingPayments) { payment in
                        // We can re-use the row view from the scheduled payments list
                        ScheduledPaymentRowView(
                            payment: payment,
                            sourceAccountName: "Account", // This data isn't in the ViewModel yet
                            targetAccountName: nil
                        )
                        if payment != viewModel.upcomingPayments.last {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var budgetSummarySection: some View {
        VStack(alignment: .leading) {
            Text("Budget Summary")
                .font(.title2)
                .fontWeight(.semibold)

            if viewModel.budgetSummary.isEmpty {
                Text("No budgets to show.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                VStack {
                    ForEach(viewModel.budgetSummary) { progress in
                        // Re-use the budget row view
                        BudgetRowView(budgetProgress: progress)
                        if progress.id != viewModel.budgetSummary.last?.id {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}


// MARK: - Preview Provider

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        // --- Create Mocks ---
        let mockAuthViewModel = AuthViewModel()
        let mockStore = AppStore()
        
        // --- Populate Mock Data ---
        mockAuthViewModel.currentUser = User(id: "123", fullName: "Robert Cobain", email: "dev@pennypath.com")
        
        let account1 = Account(id: "acc1", name: "Current Account", type: .currentAccount, institution: "Monzo", anchorBalance: 1500, anchorDate: .init(date: Date()))
        let account2 = Account(id: "acc2", name: "Credit Card", type: .creditCard, institution: "Barclays", anchorBalance: -350, anchorDate: .init(date: Date()))
        mockStore.accounts = [account1, account2]
        mockStore.calculatedBalances = ["acc1": 1500, "acc2": -350]
        
        let category = Category(id: "cat1", name: "Groceries", iconName: "cart.fill", colorHex: "#33FF57")
        mockStore.categories = [category]
        
        let budget = Budget(id: "bud1", categoryId: "cat1", amount: 400, startDate: .init(date: Date()), endDate: .init(date: Date()))
        mockStore.budgets = [budget]
        
        let payment = ScheduledPayment(id: "pay1", transactionId: "t1", sourceAccountId: "acc1", amount: 25.50, dueDate: .init(date: Date()))
        
        // --- Create and Configure Mock ViewModel ---
        let mockViewModel = DashboardViewModel()
        mockViewModel.userName = "Robert Cobain"
        mockViewModel.netWorth = 1150.00
        mockViewModel.upcomingPayments = [payment]
        mockViewModel.budgetSummary = [BudgetProgress(budget: budget, spentAmount: 120.55, category: category)]

        // --- Return View ---
        return DashboardView()
            .environmentObject(mockStore)
            .environmentObject(mockAuthViewModel)
    }
}