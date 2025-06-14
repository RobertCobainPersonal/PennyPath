//
//  AccountListViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: This ViewModel no longer fetches data itself.
//  It subscribes to the central AppStore for its data, ensuring a single source of truth.
//

import Foundation
import Combine

@MainActor
class AccountListViewModel: ObservableObject {
    
    @Published var accounts = [Account]()
    private var cancellables = Set<AnyCancellable>()
    
    /// Subscribes to the `accounts` publisher from the AppStore.
    /// - Parameter store: The central AppStore instance.
    func listenForData(store: AppStore) {
        store.$accounts
            .assign(to: \.accounts, on: self)
            .store(in: &cancellables)
    }
    
    func delete(at offsets: IndexSet) {
            let accountsToDelete = offsets.compactMap { self.accounts[$0] }
            
            Task {
                for account in accountsToDelete {
                    guard let accountId = account.id else { continue }
                    
                    do {
                        try await AccountService.shared.deleteAccount(withId: accountId)
                        print("Successfully deleted account \(accountId) and all its associated data.")
                    } catch {
                        print("Error deleting account: \(error.localizedDescription)")
                    }
                }
            }
        }
}
