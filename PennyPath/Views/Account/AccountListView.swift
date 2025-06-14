//
//  AccountListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: Now supports swipe-to-delete and presents the AddAccountView correctly.
//

import SwiftUI

struct AccountListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var store: AppStore
    
    @StateObject private var viewModel = AccountListViewModel()
    
    // We only need a simple boolean to control the "Add" sheet now
    @State private var showingAddAccountSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.accounts.isEmpty {
                    List {
                        ForEach(viewModel.accounts) { account in
                            NavigationLink {
                                AccountDetailView(account: account)
                            } label: {
                                let balance = store.calculatedBalances[account.id ?? ""] ?? 0.0
                                AccountRowView(account: account, balance: balance)
                            }
                        }
                        .onDelete(perform: viewModel.delete)
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
                        // This now toggles our simple boolean state
                        showingAddAccountSheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // The sheet is now presented using the boolean state
            .sheet(isPresented: $showingAddAccountSheet) {
                // We present the AddAccountView with a new, empty ViewModel for adding.
                AddAccountView(viewModel: AddAccountViewModel())
            }
            .onAppear {
                viewModel.listenForData(store: store)
            }
        }
    }
}


struct AccountListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthViewModel = AuthViewModel()
        let mockStore = AppStore()
        
        let sampleAccount = Account(
            id: "acc123",
            name: "Monzo",
            type: .currentAccount,
            institution: "Monzo Bank",
            anchorBalance: 2500,
            anchorDate: .init(date: Date())
        )
        mockStore.accounts = [sampleAccount]
        mockStore.calculatedBalances["acc123"] = 2500.00
        
        return AccountListView()
            .environmentObject(mockAuthViewModel)
            .environmentObject(mockStore)
    }
}
