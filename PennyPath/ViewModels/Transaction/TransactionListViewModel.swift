//
//  TransactionListViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//


//
//  TransactionListViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class TransactionListViewModel: ObservableObject {
    
    @Published var transactions = [Transaction]()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchTransactions(userId: user.uid)
            } else {
                self?.listenerRegistration?.remove()
                self?.transactions = []
            }
        }
    }
    
    private func fetchTransactions(userId: String) {
        let db = Firestore.firestore()
        let transactionsPath = "users/\(userId)/transactions"
        
        listenerRegistration?.remove() // Avoid duplicate listeners
        
        self.listenerRegistration = db.collection(transactionsPath)
            .order(by: "date", descending: true) // Show most recent first
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching transactions: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.transactions = documents.compactMap { document -> Transaction? in
                    try? document.data(as: Transaction.self)
                }
            }
    }
    
    deinit {
        print("TransactionListViewModel deinitialized, removing listener.")
        listenerRegistration?.remove()
    }
    
    func deleteTransaction(at offsets: IndexSet) {
           let transactionsToDelete = offsets.compactMap { self.transactions[$0] }
           
           Task {
               for transaction in transactionsToDelete {
                   guard let transactionId = transaction.id else { continue }
                   
                   do {
                       try await TransactionService.shared.deleteTransaction(withId: transactionId)
                       print("Successfully deleted transaction \(transactionId).")
                   } catch {
                       print("Error deleting transaction: \(error.localizedDescription)")
                   }
               }
           }
       }
}
