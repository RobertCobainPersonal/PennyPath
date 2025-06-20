//
//  AccountDetailView.swift (Enhanced - Fixed Navigation Issues)
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI
import Charts

struct AccountDetailView: View {
    @EnvironmentObject var appStore: AppStore
    @StateObject private var viewModel: AccountDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditAccount = false
    @State private var selectedChartType: ChartType = .balanceForecast
    @State private var showingUpcomingTransactions = true
    @State private var showingRecentTransactions = true
    @State private var showingAddTransaction = false
    
    let accountId: String
    
    init(accountId: String, appStore: AppStore) {
        self.accountId = accountId
        self._viewModel = StateObject(wrappedValue: AccountDetailViewModel(appStore: appStore, accountId: accountId))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Account header - now using extracted component
                AccountHeaderSection(account: viewModel.account)
                
                // Account-specific information
                if let account = viewModel.account {
                    AccountSpecificInfoSection(account: account, viewModel: viewModel)
                }
                
                // Monthly activity summary
                if viewModel.currentMonthSpending > 0 || viewModel.currentMonthIncome > 0 {
                    MonthlyActivitySection(viewModel: viewModel)
                }
                
                // Charts section - now using extracted component with refined UX
                if let account = viewModel.account {
                    ChartSection(
                        selectedChartType: $selectedChartType,
                        account: account,
                        viewModel: viewModel,
                        appStore: appStore
                    )
                }
                
                // BNPL Plans (if applicable)
                if viewModel.account?.type == .bnpl && viewModel.outstandingBNPLPlans > 0 {
                    BNPLPlansSection(viewModel: viewModel)
                }
                
                // Upcoming transactions
                UpcomingTransactionsSection(
                    viewModel: viewModel,
                    showingUpcomingTransactions: $showingUpcomingTransactions,
                    showingAddTransaction: $showingAddTransaction
                )
                
                // Recent transactions
                RecentTransactionsSection(
                    viewModel: viewModel,
                    showingRecentTransactions: $showingRecentTransactions,
                    showingAddTransaction: $showingAddTransaction
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.account?.name ?? "Account")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditAccount = true
                }) {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingEditAccount) {
            if let account = viewModel.account {
                EditAccountView(account: account)
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            if let account = viewModel.account {
                AddTransactionView(preselectedAccountId: account.id)
            }
        }
        .onAppear {
            // Set default chart type based on account type
            if let account = viewModel.account {
                selectedChartType = ChartType.defaultType(for: account.type)
            }
        }
    }
}

// MARK: - Account Specific Info Section

struct AccountSpecificInfoSection: View {
    let account: Account
    let viewModel: AccountDetailViewModel
    
    var body: some View {
        Group {
            switch account.type {
            case .credit:
                CreditCardInfoSection(account: account)
            case .loan:
                LoanInfoSection(account: account)
            case .bnpl:
                BNPLInfoSection(account: account, viewModel: viewModel)
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Credit Card Info Section

struct CreditCardInfoSection: View {
    let account: Account
    
    var body: some View {
        CardView {
            VStack(spacing: 12) {
                HStack {
                    SectionHeaderView(title: "Credit Information", icon: "creditcard")
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    DetailRowView(
                        label: "Credit Limit",
                        value: account.creditLimit?.formattedAsCurrency ?? "Not set"
                    )
                    
                    if let creditLimit = account.creditLimit, creditLimit > 0 {
                        let utilization = abs(account.balance) / creditLimit
                        
                        PercentageDetailRowView(
                            label: "Utilization",
                            percentage: utilization,
                            showProgress: true
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Loan Info Section

struct LoanInfoSection: View {
    let account: Account
    
    var body: some View {
        CardView {
            VStack(spacing: 12) {
                HStack {
                    SectionHeaderView(title: "Loan Information", icon: "banknote")
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    if let originalAmount = account.originalLoanAmount {
                        CurrencyDetailRowView(
                            label: "Original Amount",
                            amount: originalAmount,
                            showDivider: true
                        )
                    }
                    
                    if let remainingMonths = account.remainingLoanMonths {
                        DetailRowView(
                            label: "Remaining Term",
                            value: "\(remainingMonths) months",
                            showDivider: true
                        )
                    }
                    
                    if let monthlyPayment = account.monthlyPayment {
                        CurrencyDetailRowView(
                            label: "Monthly Payment",
                            amount: monthlyPayment,
                            isPositive: false,
                            showDivider: true
                        )
                    }
                    
                    if let completion = account.loanCompletionPercentage {
                        PercentageDetailRowView(
                            label: "Progress",
                            percentage: completion,
                            showProgress: true,
                            progressColor: .blue
                        )
                    }
                }
            }
        }
    }
}

// MARK: - BNPL Info Section

struct BNPLInfoSection: View {
    let account: Account
    let viewModel: AccountDetailViewModel
    
    var body: some View {
        CardView {
            VStack(spacing: 12) {
                HStack {
                    SectionHeaderView(title: "BNPL Information", icon: "calendar.badge.clock")
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    if let provider = account.bnplProvider {
                        DetailRowView(label: "Provider", value: provider)
                    }
                    
                    DetailRowView(
                        label: "Outstanding Plans",
                        value: "\(viewModel.outstandingBNPLPlans)"
                    )
                }
            }
        }
    }
}

// MARK: - Monthly Activity Section

struct MonthlyActivitySection: View {
    let viewModel: AccountDetailViewModel
    
    var body: some View {
        CardView {
            VStack(spacing: 12) {
                HStack {
                    SectionHeaderView(title: "This Month", icon: "calendar")
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Income")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.currentMonthIncome.formattedAsCurrency)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Spending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.currentMonthSpending.formattedAsCurrency)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - BNPL Plans Section

struct BNPLPlansSection: View {
    let viewModel: AccountDetailViewModel
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeaderView(title: "BNPL Plans", icon: "calendar.badge.clock")
                    Spacer()
                    
                    StatusDetailRowView(
                        label: "",
                        status: "\(viewModel.outstandingBNPLPlans) active",
                        statusColor: .blue
                    )
                }
                
                Text("Next payment due in 3 days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("View All Plans") {
                    // TODO: Navigate to BNPL plans view
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Upcoming Transactions Section

struct UpcomingTransactionsSection: View {
    let viewModel: AccountDetailViewModel
    @Binding var showingUpcomingTransactions: Bool
    @Binding var showingAddTransaction: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderView(title: "Upcoming Transactions", icon: "clock")
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingUpcomingTransactions.toggle()
                    }
                }) {
                    Image(systemName: showingUpcomingTransactions ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            if showingUpcomingTransactions {
                CardView {
                    if viewModel.upcomingTransactions.isEmpty {
                        EmptyUpcomingTransactionsView(showingAddTransaction: $showingAddTransaction)
                    } else {
                        FilledUpcomingTransactionsView(upcomingTransactions: viewModel.upcomingTransactions)
                    }
                }
            }
        }
    }
}

// MARK: - Recent Transactions Section

struct RecentTransactionsSection: View {
    let viewModel: AccountDetailViewModel
    @Binding var showingRecentTransactions: Bool
    @Binding var showingAddTransaction: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderView(title: "Recent Transactions", icon: "list.bullet")
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to transactions list filtered by this account
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingRecentTransactions.toggle()
                    }
                }) {
                    Image(systemName: showingRecentTransactions ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            if showingRecentTransactions {
                CardView {
                    if viewModel.recentTransactions.isEmpty {
                        EmptyRecentTransactionsView(showingAddTransaction: $showingAddTransaction)
                    } else {
                        FilledRecentTransactionsView(recentTransactions: viewModel.recentTransactions)
                    }
                }
            }
        }
    }
}

// MARK: - Empty States

struct EmptyUpcomingTransactionsView: View {
    @Binding var showingAddTransaction: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .foregroundColor(.gray)
                .font(.title2)
            
            Text("No upcoming transactions")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Schedule Payment") {
                showingAddTransaction = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct FilledUpcomingTransactionsView: View {
    let upcomingTransactions: [Transaction]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(upcomingTransactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                TransactionRowView(
                    transaction: transaction,
                    showAccount: false,
                    showEvent: true,
                    showDate: false,
                    style: .fullWidth,
                    showDueContext: true,
                    onTap: {
                        print("Tapped upcoming transaction: \(transaction.description)")
                    }
                )
                
                if index < min(upcomingTransactions.count, 5) - 1 {
                    Divider()
                        .padding(.horizontal)
                }
            }
            
            if upcomingTransactions.count > 5 {
                Button("View All (\(upcomingTransactions.count))") {
                    // TODO: Navigate to filtered transactions list
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.vertical, 12)
            }
        }
    }
}

struct EmptyRecentTransactionsView: View {
    @Binding var showingAddTransaction: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .foregroundColor(.gray)
                .font(.title2)
            
            Text("No recent transactions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Transaction") {
                showingAddTransaction = true
            }
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct FilledRecentTransactionsView: View {
    let recentTransactions: [Transaction]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(recentTransactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                TransactionRowView(
                    transaction: transaction,
                    showAccount: false,
                    showEvent: true,
                    showDate: true,
                    style: .fullWidth,
                    showDueContext: false,
                    onTap: {
                        print("Tapped recent transaction: \(transaction.description)")
                    }
                )
                
                if index < min(recentTransactions.count, 5) - 1 {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Preview Provider
struct AccountDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountDetailView(accountId: "acc-current", appStore: AppStore())
                .environmentObject(AppStore())
        }
    }
}
