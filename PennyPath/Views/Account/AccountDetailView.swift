//
//  AccountDetailView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//
//  REFACTORED: This view now gets the calculated balance from the AppStore
//  and passes it into its ViewModel.
//

import SwiftUI

struct AccountDetailView: View {
    
    // We get the store from the environment to look up the balance.
    @EnvironmentObject var store: AppStore
    
    // The account to display is passed in.
    private let account: Account
    
    // The ViewModel is now created inside the initializer.
    @StateObject private var viewModel: AccountDetailViewModel
    
    init(account: Account) {
        self.account = account
        // We temporarily initialize the ViewModel with a balance of 0.
        // The correct balance will be looked up from the store when the view appears.
        // This approach is necessary because we cannot access the environment store during initialization.
        _viewModel = StateObject(wrappedValue: AccountDetailViewModel(account: account, balance: 0.0))
    }
    
    // A helper to find the correct, live balance for this account from the AppStore.
    private var liveBalance: Double {
        store.calculatedBalances[account.id ?? ""] ?? account.anchorBalance
    }
    
    var body: some View {
        // We create a new instance of the ViewModel with the live balance
        // and assign it to our state object. This ensures the view has the correct data.
        let liveViewModel = AccountDetailViewModel(account: account, balance: liveBalance)
        
        List {
            Section(header: Text("Account Details")) {
                HStack {
                    Text("Type")
                    Spacer()
                    Text(liveViewModel.accountTypeLabel)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Current Balance")
                    Spacer()
                    // Use the ViewModel's formatted property
                    Text(liveViewModel.currentBalanceFormatted)
                        .fontWeight(.bold)
                        .foregroundColor(liveViewModel.alertThresholdHit ? .red : .primary)
                }

                if let creditLimit = account.creditLimit {
                    HStack {
                        Text("Credit Limit")
                        Spacer()
                        Text(creditLimit, format: .currency(code: account.currency))
                    }

                    if let usage = liveViewModel.creditLimitUsage {
                        ProgressView(value: usage) {
                            Text("Utilisation")
                        }
                        .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                
                // All other rows displaying account info...
                // These can stay the same as they read directly from the 'account' object.
                if let apr = account.apr {
                    HStack {
                        Text("APR")
                        Spacer()
                        Text("\(apr, specifier: "%.2f")%")
                    }
                }
            }
            
            // The section for transactions remains the same
            Section(header: Text("Recent Transactions")) {
                if liveViewModel.transactions.isEmpty {
                    Text("No transactions found for this account.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(liveViewModel.transactions) { transaction in
                        let category = store.categories.first { $0.id == transaction.categoryId }
                        TransactionRowView(transaction: transaction, category: category, currencyCode: account.currency)
                    }
                }
            }
        }
        .navigationTitle(account.name)
        .onAppear {
            // When the view appears, we tell the ViewModel to fetch its transactions.
            // The ViewModel itself is updated with the live balance at the start of the body.
            liveViewModel.fetchTransactions()
        }
    }
}


struct AccountDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStore = AppStore()
        
        let mockAccount = Account(
            id: "acc1",
            name: "Barclaycard",
            type: .creditCard,
            institution: "Barclays",
            anchorBalance: -450.75,
            anchorDate: .init(date: Date()),
            creditLimit: 1500
        )
        mockStore.accounts = [mockAccount]
        mockStore.calculatedBalances["acc1"] = -450.75
        
        return NavigationView {
            AccountDetailView(account: mockAccount)
                .environmentObject(mockStore)
        }
    }
}
