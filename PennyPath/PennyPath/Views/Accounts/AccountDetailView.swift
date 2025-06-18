//
//  AccountDetailView.swift (Enhanced - Fixed Navigation Issues)
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
                
                // Interactive Charts Section
                chartSection
                
                // BNPL Plans Section (if applicable)
                if viewModel.account?.type == .bnpl && viewModel.outstandingBNPLPlans > 0 {
                    bnplPlansSection
                }
                
                // Upcoming payments first (more actionable)
                upcomingTransactionsSection
                
                // Recent transactions section (now second)
                recentTransactionsSection
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.account?.name ?? "Account")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                enhancedThreeDotsMenu
            }
        }
        .sheet(isPresented: $showingEditAccount) {
            if let account = viewModel.account {
                EditAccountView(account: account)
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(preselectedAccountId: accountId)
        }
        .onReceive(appStore.$accounts) { accounts in
            if !accounts.contains(where: { $0.id == accountId }) {
                dismiss()
            }
        }
        .onAppear {
            // Hide the global FAB when this view appears
            NotificationCenter.default.post(name: Notification.Name("HideGlobalFAB"), object: nil)
        }
        .onDisappear {
            // Show the global FAB when this view disappears
            NotificationCenter.default.post(name: Notification.Name("ShowGlobalFAB"), object: nil)
        }
    }
    
    // MARK: - View Components
    
    private var accountHeaderSection: some View {
        Group {
            if let account = viewModel.account {
                CardView {
                    VStack(spacing: 16) {
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
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Account Insights", icon: "chart.line.uptrend.xyaxis")
                
                Spacer()
                
                Picker("Chart Type", selection: $selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.shortName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            CardView {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedChartType.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(selectedChartType.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    chartPlaceholder
                }
            }
        }
    }
    
    private var bnplPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Active BNPL Plans", icon: "calendar.badge.clock")
            
            CardView {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Outstanding Plans")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(viewModel.outstandingBNPLPlans)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        if let nextPayment = viewModel.nextBNPLPayment {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Next Payment")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
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
                    
                    Divider()
                    
                    Button(action: {
                        print("View all BNPL plans")
                    }) {
                        HStack {
                            Text("View All Plans & Schedule")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private var upcomingTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingUpcomingTransactions.toggle()
                }
            }) {
                HStack {
                    sectionHeader(title: "Upcoming Transactions", icon: "calendar.badge.clock")
                    
                    Spacer()
                    
                    if !viewModel.upcomingTransactions.isEmpty {
                        Text("\(viewModel.upcomingTransactions.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(8)
                    }
                    
                    Image(systemName: showingUpcomingTransactions ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showingUpcomingTransactions {
                if viewModel.upcomingTransactions.isEmpty {
                    emptyStateView(
                        icon: "checkmark.circle",
                        title: "All caught up!",
                        subtitle: "No upcoming payments in the next 30 days"
                    )
                } else {
                    CardView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.upcomingTransactions) { transaction in
                                NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                    TransactionRowView(
                                        transaction: transaction,
                                        showAccount: false,    // Remove redundant account name
                                        showEvent: true,       // Keep event tags
                                        showDate: true,        // Show temporal context
                                        style: .compact,       // Use compact style
                                        showDueContext: true,  // Show "Due in X days"
                                        onTap: {}             // Show chevron for navigation
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                if transaction.id != viewModel.upcomingTransactions.last?.id {
                                    Divider()
                                        .padding(.leading, 64) // Align with TransactionRowView
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingRecentTransactions.toggle()
                }
            }) {
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
                    
                    Image(systemName: showingRecentTransactions ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showingRecentTransactions {
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
                                NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                    TransactionRowView(
                                        transaction: transaction,
                                        showAccount: false, // Remove redundant account name
                                        showEvent: true,    // Keep event tags
                                        showDate: true,     // Show transaction dates
                                        style: .compact,    // Use compact style
                                        onTap: {}          // Show chevron for navigation
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                if transaction.id != viewModel.recentTransactions.last?.id {
                                    Divider()
                                        .padding(.leading, 64) // Consistent divider alignment
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
    
    private var enhancedThreeDotsMenu: some View {
        Menu {
            Button(action: {
                print("Add transaction to this account")
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Transaction")
                }
            }
            
            Button(action: {
                print("Transfer money from/to this account")
            }) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("Transfer Money")
                }
            }
            
            Divider()
            
            Button("Edit Account") {
                showingEditAccount = true
            }
            
            Button("View All Transactions") {
                print("View all transactions")
            }
            
            Divider()
            
            Button(action: {
                print("Export account data")
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Data")
                }
            }
            
            if viewModel.account?.type == .bnpl {
                Button(action: {
                    print("Manage BNPL plans")
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                        Text("Manage BNPL Plans")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .fontWeight(.semibold)
        }
    }
    
    // MARK: - Chart Components
    
    private var chartPlaceholder: some View {
        VStack(spacing: 16) {
            switch selectedChartType {
            case .balanceForecast:
                balanceForecastChart
            case .spendingTrends:
                spendingTrendsChart
            case .paymentSchedule:
                paymentScheduleChart
            }
        }
        .frame(height: 200)
    }
    
    private var balanceForecastChart: some View {
        VStack(spacing: 8) {
            HStack {
                Text("30-Day Balance Projection")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("+£1,247")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(
                    VStack {
                        Text("📈")
                            .font(.system(size: 40))
                        Text("Balance Forecast Chart")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("(Shows projected balance with scheduled payments)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
    
    private var spendingTrendsChart: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Spending by Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Food & Dining") {
                    // TODO: Toggle category filter
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(
                    VStack {
                        Text("📊")
                            .font(.system(size: 40))
                        Text("Spending Trends Chart")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("(Stacked bars by category, toggle merchant view)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
    
    private var paymentScheduleChart: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Payment Calendar")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("5 upcoming")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(
                    VStack {
                        Text("📅")
                            .font(.system(size: 40))
                        Text("Payment Schedule Calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("(Mini calendar with payment dots/amounts)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
    
    // MARK: - Account-Specific Sections
    
    private func creditCardSpecificSection(for account: Account) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Credit Information", icon: "creditcard")
            
            CardView {
                VStack(spacing: 16) {
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
                Button(action: {
                    showingAddTransaction = true
                }) {
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundColor(.blue) // Make it actionable blue instead of secondary
                }
                .buttonStyle(.plain)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
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
}

// MARK: - Chart Types Enum
enum ChartType: String, CaseIterable {
    case balanceForecast = "balance"
    case spendingTrends = "spending"
    case paymentSchedule = "schedule"
    
    var displayName: String {
        switch self {
        case .balanceForecast: return "Balance Forecast"
        case .spendingTrends: return "Spending Trends"
        case .paymentSchedule: return "Payment Schedule"
        }
    }
    
    var shortName: String {
        switch self {
        case .balanceForecast: return "Balance"
        case .spendingTrends: return "Trends"
        case .paymentSchedule: return "Schedule"
        }
    }
    
    var subtitle: String {
        switch self {
        case .balanceForecast: return "30-day projection with scheduled payments"
        case .spendingTrends: return "Category breakdown and merchant analysis"
        case .paymentSchedule: return "Upcoming payments calendar view"
        }
    }
}

// MARK: - Preview Provider
struct AccountDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountDetailView(accountId: "acc-golf", appStore: AppStore())
                .environmentObject(AppStore())
        }
    }
}
