//
//  AccountListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

import SwiftUI

struct AccountListView: View {
    // ViewModel for handling authentication state
    @EnvironmentObject var authViewModel: AuthViewModel
    // ViewModel for fetching and holding the account list
    @StateObject private var accountViewModel = AccountListViewModel()
    
    // State to control the presentation of the AddAccountView sheet
    @State private var showingAddAccountSheet = false

    var body: some View {
        NavigationStack {
            Group {
                // If there are accounts, show them in a list
                if !accountViewModel.accounts.isEmpty {
                    List(accountViewModel.accounts) { account in
                        AccountRowView(account: account)
                    }
                } else {
                    // Show a helpful placeholder if no accounts exist
                    ContentUnavailableView(
                        "No Accounts Yet",
                        systemImage: "wallet.pass",
                        description: Text("Tap the '+' button to add your first account and get started.")
                    )
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                // Button to present the AddAccountView sheet
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddAccountSheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                // Sign out button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingAddAccountSheet) {
                AddAccountView() // Presents the existing AddAccountView
            }
            .onAppear {
                // Fetch accounts when the view appears
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
