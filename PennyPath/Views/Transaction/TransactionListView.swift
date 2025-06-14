//
//  TransactionListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import SwiftUI

// A new helper struct to determine which sheet to show
enum TransactionSheet: Identifiable {
    case new
    case edit(transaction: Transaction)
    
    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let transaction):
            return transaction.id ?? UUID().uuidString
        }
    }
}

struct TransactionListView: View {
    
    @StateObject private var viewModel = TransactionListViewModel()
    @EnvironmentObject var store: AppStore
    
    // This state variable will now control our sheets
    @State private var activeSheet: TransactionSheet?
    
    private var currencyLookup: [String: String] {
        Dictionary(uniqueKeysWithValues: store.accounts.map { ($0.id ?? "", $0.currency) })
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.transactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: Text("Your transactions will appear here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.transactions) { transaction in
                            let category = store.categories.first { $0.id == transaction.categoryId }
                            let currencyCode = currencyLookup[transaction.accountId] ?? "GBP"
                            
                            TransactionRowView(transaction: transaction, category: category, currencyCode: currencyCode)
                                // New swipe actions for Edit and Delete
                                .swipeActions {
                                    Button(role: .destructive) {
                                        viewModel.delete(transaction)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }

                                    // Do not show "Edit" for transfers
                                    if !transaction.description.lowercased().contains("transfer") {
                                        Button {
                                            activeSheet = .edit(transaction: transaction)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activeSheet = .new
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // This single sheet modifier handles both adding and editing
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .new:
                    AddTransactionContainerView()
                case .edit(let transaction):
                    // Determine which view to show based on the transaction amount
                    if transaction.amount < 0 {
                        AddExpenseView(
                            viewModel: AddExpenseViewModel(transactionToEdit: transaction),
                            onSave: { activeSheet = nil }
                        )
                    } else {
                        AddIncomeView(
                            viewModel: AddIncomeViewModel(transactionToEdit: transaction),
                            onSave: { activeSheet = nil }
                        )
                    }
                }
            }
        }
    }
}

// We also need to update the ViewModel to have a direct delete method
extension TransactionListViewModel {
    func delete(_ transaction: Transaction) {
        Task {
            guard let transactionId = transaction.id else { return }
            do {
                try await TransactionService.shared.deleteTransaction(withId: transactionId)
                print("Successfully deleted transaction \(transactionId).")
            } catch {
                print("Error deleting transaction: \(error.localizedDescription)")
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
