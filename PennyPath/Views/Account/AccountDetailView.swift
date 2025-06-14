//
//  AccountDetailView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//
//  REFACTORED: Now includes an "Edit" button to present the AddAccountView sheet.
//

import SwiftUI

struct AccountDetailView: View {
    
    @EnvironmentObject var store: AppStore
    
    // 1. A new state variable to control the presentation of our edit sheet
    @State private var isPresentingEditSheet = false
    
    private let account: Account
    @StateObject private var viewModel: AccountDetailViewModel
    
    init(account: Account) {
        self.account = account
        _viewModel = StateObject(wrappedValue: AccountDetailViewModel(account: account, balance: 0.0))
    }
    
    private var liveBalance: Double {
        store.calculatedBalances[account.id ?? ""] ?? account.anchorBalance
    }
    
    var body: some View {
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
                
                if let apr = account.apr {
                    HStack {
                        Text("APR")
                        Spacer()
                        Text("\(apr, specifier: "%.2f")%")
                    }
                }
            }
            
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
        .toolbar {
            // 2. A new ToolbarItem with a button to trigger the sheet
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isPresentingEditSheet.toggle()
                }
            }
        }
        // 3. The sheet modifier that presents our AddAccountView in edit mode
        .sheet(isPresented: $isPresentingEditSheet) {
            AddAccountView(viewModel: AddAccountViewModel(accountToEdit: account))
        }
        .onAppear {
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
