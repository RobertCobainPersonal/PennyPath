//
//  AccountDetailViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AccountDetailViewModel: ObservableObject {
    
    @Published var transactions = [Transaction]()
    
    private let account: Account
    private var listenerRegistration: ListenerRegistration?
    
    init(account: Account) {
        self.account = account
    }
    
    func fetchTransactions() {
        guard let userId = Auth.auth().currentUser?.uid, let accountId = account.id else {
            print("User or account ID not found.")
            return
        }
        
        let db = Firestore.firestore()
        let transactionsPath = "users/\(userId)/transactions"
        
        // Remove previous listener to prevent duplication if view reappears
        listenerRegistration?.remove()
        
        // Query for transactions linked to this specific account
        self.listenerRegistration = db.collection(transactionsPath)
            .whereField("accountId", isEqualTo: accountId)
            .order(by: "date", descending: true)
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
    
    // Clean up listener
    deinit {
        print("AccountDetailViewModel deinitialized, removing listener.")
        listenerRegistration?.remove()
    }
}

extension AccountDetailViewModel {
    
    var accountName: String {
        account.name
    }

    var currentBalanceFormatted: String {
        String(format: "£%.2f", account.currentBalance)
    }

    var isCreditAccount: Bool {
        switch account.type {
        case .creditCard, .loan: return true
        default: return false
        }
    }

    var creditLimitUsage: Double? {
        guard let limit = account.creditLimit, limit > 0 else { return nil }
        return (account.currentBalance / limit).clamped(to: 0...1)
    }

    var isBNPLAccount: Bool {
        account.type == .bnpl || account.isBNPL == true
    }

    var alertThresholdHit: Bool {
        if let threshold = account.alertThreshold {
            return account.currentBalance < threshold
        }
        return false
    }

    var accountTypeLabel: String {
        account.type.rawValue
    }

    var formattedPaymentDueDate: String? {
        guard let date = account.paymentDueDate?.dateValue() else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var formattedOriginationDate: String? {
        guard let date = account.originationDate?.dateValue() else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
