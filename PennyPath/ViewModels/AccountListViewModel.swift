//
//  AccountListViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//


//
//  AccountListViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AccountListViewModel: ObservableObject {
    
    @Published var accounts = [Account]()
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?

    func fetchAccounts() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not found for fetching accounts.")
            return
        }
        
        // The path where accounts are saved, derived from AddAccountView.swift logic
        let collectionPath = "users/\(userId)/accounts"
        
        // Remove previous listener to prevent duplication
        listenerRegistration?.remove()
        
        self.listenerRegistration = db.collection(collectionPath)
            .order(by: "lastUpdated", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching account documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.accounts = documents.compactMap { document -> Account? in
                    do {
                        // Decode the Firestore document into our Account model
                        return try document.data(as: Account.self)
                    } catch {
                        print("Error decoding document \(document.documentID): \(error)")
                        return nil
                    }
                }
            }
    }
    
    // Clean up listener
    deinit {
        print("AccountListViewModel deinitialized, removing listener.")
        listenerRegistration?.remove()
    }
}
