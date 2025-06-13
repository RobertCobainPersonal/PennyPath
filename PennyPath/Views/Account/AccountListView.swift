//
//  AccountListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: This view now gets the list of accounts and their calculated
//  balances from the central AppStore.
//

import SwiftUI

struct AccountListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var store: AppStore // Get the store from the environment
    
    @State private var showingAddAccountSheet = false

    var body: some View {
        NavigationStack {
            Group {
                // Use the accounts list from the AppStore
                if !store.accounts.isEmpty {
                    List(store.accounts) { account in
                        NavigationLink {
                            AccountDetailView(account: account)
                        } label: {
                            // 1. Look up the calculated balance for this account.
                            // We provide a default of 0.0 if the balance hasn't been calculated yet.
                            let balance = store.calculatedBalances[account.id ?? ""] ?? 0.0
                            
                            // 2. Pass the account and its calculated balance into the row view.
                            AccountRowView(account: account, balance: balance)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Accounts Yet",
                        systemImage: "wallet.pass",
                        description: Text("Tap the '+' button to add your first account and get started.")
                    )
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddAccountSheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingAddAccountSheet) {
                AddAccountView()
            }
            // No .onAppear is needed here anymore, as the AppStore handles fetching.
        }
    }
}


struct AccountListView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mocks for the preview
        let mockAuthViewModel = AuthViewModel()
        let mockStore = AppStore()
        
        // Create a sample account
        let sampleAccount = Account(
            id: "acc123",
            name: "Monzo",
            type: .currentAccount,
            institution: "Monzo Bank",
            anchorBalance: 2500,
            anchorDate: .init(date: Date())
        )
        mockStore.accounts = [sampleAccount]
        
        // Set its calculated balance
        mockStore.calculatedBalances["acc123"] = 2500.00
        
        return AccountListView()
            .environmentObject(mockAuthViewModel)
            .environmentObject(mockStore)
    }
}
