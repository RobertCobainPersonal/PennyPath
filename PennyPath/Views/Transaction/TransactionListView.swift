//
//  TransactionListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//


//
//  TransactionListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import SwiftUI

struct TransactionListView: View {
    
    @StateObject private var viewModel = TransactionListViewModel()
    @EnvironmentObject var store: AppStore // Get accounts from the central store
    
    @State private var showingAddSheet = false
    
    // Create a quick lookup for currency codes based on account ID
    private var currencyLookup: [String: String] {
        Dictionary(uniqueKeysWithValues: store.accounts.map { ($0.id ?? "", $0.currency) })
    }
    
    var body: some View {
        NavigationStack {
            List(viewModel.transactions) { transaction in
                // Look up the currency for the transaction's account, defaulting to GBP.
                let currencyCode = currencyLookup[transaction.accountId] ?? "GBP"
                TransactionRowView(transaction: transaction, currencyCode: currencyCode)
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                // This call is now simple and correct.
                AddTransactionContainerView()
            }
        }
    }
}

struct TransactionListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionListView()
            .environmentObject(AppStore())
    }
}
