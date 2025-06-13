//
//  AccountDetailView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import SwiftUI

struct AccountDetailView: View {
    
    @StateObject private var viewModel: AccountDetailViewModel
    @EnvironmentObject var store: AppStore // Access the central store for BNPL plans
    
    private let account: Account
    
    // A computed property to filter BNPL plans for this specific account
    private var associatedBNPLPlans: [BNPLPlan] {
        store.bnplPlans.filter { $0.provider.lowercased() == account.institution.lowercased() }
    }
    
    init(account: Account) {
        self.account = account
        _viewModel = StateObject(wrappedValue: AccountDetailViewModel(account: account))
    }
    
    var body: some View {
        List {
            // Section for key account details
            Section(header: Text("Account Details")) {
                HStack {
                    Text("Type")
                    Spacer()
                    Text(account.type.rawValue)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Current Balance")
                    Spacer()
                    Text(account.currentBalance, format: .currency(code: account.currency))
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.alertThresholdHit ? .red : .primary)
                }

                if let creditLimit = account.creditLimit {
                    HStack {
                        Text("Credit Limit")
                        Spacer()
                        Text(creditLimit, format: .currency(code: account.currency))
                    }

                    if let usage = viewModel.creditLimitUsage {
                        ProgressView(value: usage) {
                            Text("Utilisation")
                        }
                        .progressViewStyle(LinearProgressViewStyle())
                    }
                }

                if let paymentDue = viewModel.formattedPaymentDueDate {
                    HStack {
                        Text("Payment Due")
                        Spacer()
                        Text(paymentDue)
                    }
                }

                if let apr = account.apr {
                    HStack {
                        Text("APR")
                        Spacer()
                        Text("\(apr, specifier: "%.2f")%")
                    }
                }

                if viewModel.isBNPLAccount, let outstanding = account.outstandingBalance {
                    HStack {
                        Text("Outstanding BNPL")
                        Spacer()
                        Text(outstanding, format: .currency(code: account.currency))
                    }
                }

                if let origin = viewModel.formattedOriginationDate {
                    HStack {
                        Text("Start Date")
                        Spacer()
                        Text(origin)
                    }
                }

                if let counterparty = account.counterparty {
                    HStack {
                        Text("Counterparty")
                        Spacer()
                        Text(counterparty)
                    }
                }

                if let creditor = account.originalCreditor {
                    HStack {
                        Text("Original Creditor")
                        Spacer()
                        Text(creditor)
                    }
                }

                if let settlement = account.settlementAmount {
                    HStack {
                        Text("Settlement Amount")
                        Spacer()
                        Text(settlement, format: .currency(code: account.currency))
                    }
                }

                if viewModel.alertThresholdHit {
                    Text("⚠️ Below Alert Threshold")
                        .foregroundColor(.red)
                }

                HStack {
                    Text("Institution")
                    Spacer()
                    Text(account.institution)
                        .foregroundColor(.secondary)
                }
            }
            
            // Section that appears only for BNPL accounts
            if account.type == .bnpl {
                Section(header: Text("Associated BNPL Plans")) {
                    if associatedBNPLPlans.isEmpty {
                        Text("No plans found for \(account.institution).")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(associatedBNPLPlans) { plan in
                            Text(plan.planName)
                        }
                    }
                    
                    NavigationLink("Manage All BNPL Plans") {
                        BNPLPlanListView()
                    }
                }
            }
            
            // Section to display transactions
            Section(header: Text("Recent Transactions")) {
                if viewModel.transactions.isEmpty {
                    Text("No transactions found for this account.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.transactions) { transaction in
                        // Find the category object that matches the transaction's categoryId
                        let category = store.categories.first { $0.id == transaction.categoryId }
                        
                        // Pass both the transaction and the found category to the row view
                        TransactionRowView(transaction: transaction, category: category, currencyCode: account.currency)
                    }
                }
            }
        }
        .navigationTitle(account.name)
        .onAppear {
            viewModel.fetchTransactions()
        }
    }
}

// MARK: - SwiftUI Preview

struct AccountDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockBNPLAccount = Account(
            name: "Klarna",
            type: .bnpl,
            institution: "Klarna",
            currentBalance: -150.00
        )
        
        let mockStore = AppStore()
        let samplePlan = BNPLPlan(provider: "Klarna", planName: "Pay in 3", feeType: .none, installments: 3, paymentFrequency: .monthly)
        let otherPlan = BNPLPlan(provider: "Zilch", planName: "Pay in 4", feeType: .none, installments: 4, paymentFrequency: .biweekly)
        
        mockStore.bnplPlans = [samplePlan, otherPlan]
        
        return NavigationView {
            AccountDetailView(account: mockBNPLAccount)
                .environmentObject(mockStore)
        }
    }
}
