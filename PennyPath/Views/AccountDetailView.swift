//
//  AccountDetailView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import SwiftUI

struct AccountDetailView: View {
    
    @StateObject private var viewModel: AccountDetailViewModel
    
    private let account: Account
    
    // Initializer to pass the selected account and set up the StateObject
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
                    Text(viewModel.accountTypeLabel)
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
        // Create a mock account to use for the preview
        let mockCreditCard = Account(
            id: "cc123",
            name: "Barclaycard Platinum",
            type: .creditCard,
            institution: "Barclays",
            currentBalance: 450.75,
            creditLimit: 1500.00
        )
        
        // It's good practice to wrap previews in a NavigationView
        // to see the navigation title correctly.
        NavigationView {
            AccountDetailView(account: mockCreditCard)
        }
    }
}
