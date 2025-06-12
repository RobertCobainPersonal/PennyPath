//
//  AccountListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: Wrapped account rows in a NavigationLink.
//

import SwiftUI

struct AccountListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var accountViewModel = AccountListViewModel()
    
    @State private var showingAddAccountSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if !accountViewModel.accounts.isEmpty {
                    List(accountViewModel.accounts) { account in
                        // Wrap the existing row view in a NavigationLink
                        NavigationLink {
                            // Destination is our new detail view
                            AccountDetailView(account: account)
                        } label: {
                            AccountRowView(account: account)
                        }
                    }
                } else {
                    // ... (ContentUnavailableView remains the same)
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
            .onAppear {
                accountViewModel.fetchAccounts()
            }
        }
    }
}


struct AccountListView_Previews: PreviewProvider {
    static var previews: some View {
        // Updated preview to reflect the new design
        let mockAuthViewModel = AuthViewModel()
        mockAuthViewModel.currentUser = User(id: "123", fullName: "Jane Doe", email: "jane.doe@example.com")
        
        return AccountListView()
            .environmentObject(mockAuthViewModel)
    }
}
