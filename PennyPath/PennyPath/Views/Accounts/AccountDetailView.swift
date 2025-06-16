//
//  AccountDetailView.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

struct AccountDetailView: View {
    @EnvironmentObject var appStore: AppStore
    @StateObject private var viewModel: AccountDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditAccount = false
    
    let accountId: String
    
    init(accountId: String, appStore: AppStore) {
        self.accountId = accountId
        self._viewModel = StateObject(wrappedValue: AccountDetailViewModel(appStore: appStore, accountId: accountId))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Account header section
                accountHeaderSection
                
                // Account-specific information section
                if let account = viewModel.account {
                    accountSpecificSection(for: account)
                }
                
                // Current month activity
                if viewModel.currentMonthSpending > 0 || viewModel.currentMonthIncome > 0 {
                    monthlyActivitySection
                }
                
                // Quick actions for this account
                quickActionsSection
                
                // Recent transactions section
                recentTransactionsSection
                
                // Upcoming transactions section
                if !viewModel.upcomingTransactions.isEmpty {
                    upcomingTransactionsSection
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.account?.name ?? "Account")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Account") {
                        showingEditAccount = true
                    }
                    Button("Transfer Money", action: { /* TODO */ })
                    Button("View All Transactions", action: { /* TODO */ })
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingEditAccount) {
            if let account = viewModel.account {
                EditAccountView(account: account)
            }
        }
        .onReceive(appStore.$accounts) { accounts in
            // If the account was deleted, dismiss this view
            if !accounts.contains(where: { $0.id == accountId }) {
                dismiss()
            }
        }
    }
    
    // MARK: - View Components
    
    private var accountHeaderSection: some View {
        Group {
            if let account = viewModel.account {
                CardView {
                    VStack(spacing: 16) {
                        // Account icon and type
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: account.type.color).opacity(0.15))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: account.type.icon)
                                    .font(.title)
                                    .foregroundColor(Color(hex: account.type.color))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text(account.type.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Balance and stats
                        VStack(spacing: 12) {
                            HStack {
                                Text("Current Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(account.balance.formattedAsCurrency)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(account.balance >= 0 ? .primary : .red)
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Transactions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(viewModel.transactionCount)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Account Type")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(account.type.displayName)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func accountSpecificSection(for account: Account) -> some View {
        switch account.type {
        case .credit:
            creditCardSpecificSection(for: account)
        case .loan:
            loanSpecificSection(for: account)
        case .bnpl:
            bnplSpecificSection(for: account)
        default:
            EmptyView()
        }
    }
    
    private func creditCardSpecificSection(for account: Account) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Credit Information", icon: "creditcard")
            
            CardView {
                VStack(spacing: 16) {
                    // Credit limit and available credit
                    if let creditLimit = account.creditLimit {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Credit Limit")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(creditLimit.formattedAsCurrency)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Available Credit")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text((account.availableCredit ?? 0).formattedAsCurrency)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Divider()
                        
                        // Credit utilization
                        if let utilization = account.creditUtilization {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Credit Utilization")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(utilization * 100))%")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(utilization > 0.7 ? .red : utilization > 0.3 ? .orange : .green)
                                }
                                
                                ProgressView(value: utilization, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: utilization > 0.7 ? .red : utilization > 0.3 ? .orange : .green))
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                                
                                Text("Keep utilization below 30% for optimal credit score")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func loanSpecificSection(for account: Account) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Loan Information", icon: "house")
            
            CardView {
                VStack(spacing: 16) {
                    // Loan progress
                    if let originalAmount = account.originalLoanAmount,
                       let progress = account.loanProgress {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Loan Progress")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(progress * 100))% paid")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            ProgressView(value: progress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                            
                            HStack {
                                Text("Original: \(originalAmount.formattedAsCurrency)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Remaining: \(abs(account.balance).formattedAsCurrency)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                    }
                    
                    // Loan terms
                    HStack {
                        if let startDate = account.loanStartDate {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(startDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        if let termMonths = account.loanTermMonths {
                            VStack(alignment: .center, spacing: 4) {
                                Text("Term")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(termMonths) months")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        if let interestRate = account.interestRate {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Interest Rate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(interestRate, specifier: "%.1f")%")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    if let monthlyPayment = account.monthlyPayment {
                        Divider()
                        
                        HStack {
                            Text("Monthly Payment")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(monthlyPayment.formattedAsCurrency)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }
    
    private func bnplSpecificSection(for account: Account) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "BNPL Information", icon: "calendar.badge.clock")
            
            CardView {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Provider")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(account.bnplProvider ?? "Unknown")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Outstanding Plans")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(viewModel.outstandingBNPLPlans)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if viewModel.nextBNPLPayment != nil {
                        Divider()
                        
                        HStack {
                            Text("Next Payment")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let nextPayment = viewModel.nextBNPLPayment {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(abs(nextPayment.amount).formattedAsCurrency)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text(nextPayment.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var monthlyActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "This Month", icon: "calendar")
            
            HStack(spacing: 16) {
                // Monthly spending card
                if viewModel.currentMonthSpending > 0 {
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                
                                Spacer()
                                
                                Text("Spent")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(viewModel.currentMonthSpending.formattedAsCurrency)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Monthly income card
                if viewModel.currentMonthIncome > 0 {
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                
                                Spacer()
                                
                                Text("Received")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(viewModel.currentMonthIncome.formattedAsCurrency)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Quick Actions", icon: "bolt")
            
            CardView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(viewModel.suggestedActions.prefix(4)) { action in
                        accountActionButton(action: action)
                    }
                }
            }
        }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Recent Transactions", icon: "list.bullet")
                
                Spacer()
                
                if viewModel.transactionCount > 10 {
                    Button("View All") {
                        // TODO: Navigate to full transaction list
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            if viewModel.recentTransactions.isEmpty {
                emptyStateView(
                    icon: "plus.circle",
                    title: "No transactions yet",
                    subtitle: "Add your first transaction to get started"
                )
            } else {
                CardView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.recentTransactions) { transaction in
                            TransactionRowView(transaction: transaction, showAccount: false)
                            
                            if transaction.id != viewModel.recentTransactions.last?.id {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var upcomingTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Upcoming Payments", icon: "calendar.badge.clock")
            
            CardView {
                VStack(spacing: 12) {
                    ForEach(viewModel.upcomingTransactions) { transaction in
                        UpcomingPaymentRow(transaction: transaction)
                        
                        if transaction.id != viewModel.upcomingTransactions.last?.id {
                            Divider()
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
    
    private func accountActionButton(action: AccountAction) -> some View {
        Button(action: {
            // TODO: Handle action
        }) {
            VStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.title2)
                    .foregroundColor(action.color)
                
                Text(action.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transaction Row Component
struct TransactionRowView: View {
    let transaction: Transaction
    let showAccount: Bool
    @EnvironmentObject var appStore: AppStore
    
    var body: some View {
        Button(action: {
            // TODO: Navigate to transaction detail or edit
        }) {
            HStack(spacing: 12) {
                // Transaction icon based on amount
                ZStack {
                    Circle()
                        .fill(transaction.amount >= 0 ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: transaction.amount >= 0 ? "arrow.down" : "arrow.up")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(transaction.amount >= 0 ? .green : .red)
                }
                
                // Transaction info
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.description)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let category = appStore.categories.first(where: { $0.id == transaction.categoryId }) {
                            Text("• \(category.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Amount and arrow
                VStack(alignment: .trailing, spacing: 4) {
                    Text(transaction.amount.formattedAsCurrency)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(transaction.amount >= 0 ? .green : .primary)
                    
                    if transaction.isScheduled {
                        Text("Scheduled")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview Provider
struct AccountDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountDetailView(accountId: "acc-credit", appStore: AppStore())
                .environmentObject(AppStore())
        }
    }
}

struct TransactionRowView_Previews: PreviewProvider {
    static var previews: some View {
        let mockTransaction = Transaction(
            userId: "test",
            accountId: "test",
            categoryId: "cat-food",
            amount: -8.45,
            description: "Pret A Manger"
        )
        
        VStack {
            TransactionRowView(transaction: mockTransaction, showAccount: false)
                .environmentObject(AppStore())
            
            Divider()
            
            TransactionRowView(
                transaction: Transaction(
                    userId: "test",
                    accountId: "test",
                    amount: 2800.00,
                    description: "Monthly Salary"
                ),
                showAccount: false
            )
            .environmentObject(AppStore())
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
