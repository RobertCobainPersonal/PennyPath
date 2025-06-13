//
//  AccountDetailViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//
//  REFACTORED: This ViewModel now works with the calculated balance
//  passed in from the View, rather than reading a stored property.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AccountDetailViewModel: ObservableObject {
    
    @Published var transactions = [Transaction]()
    
    // The specific account and its calculated balance are now passed in.
    private let account: Account
    private let balance: Double
    
    private var listenerRegistration: ListenerRegistration?
    
    init(account: Account, balance: Double) {
        self.account = account
        self.balance = balance
    }
    
    func fetchTransactions() {
        guard let userId = Auth.auth().currentUser?.uid, let accountId = account.id else {
            print("User or account ID not found.")
            return
        }
        
        let db = Firestore.firestore()
        let transactionsPath = "users/\(userId)/transactions"
        
        listenerRegistration?.remove()
        
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
    
    deinit {
        print("AccountDetailViewModel deinitialized, removing listener.")
        listenerRegistration?.remove()
    }
}

// MARK: - Computed Properties for UI
extension AccountDetailViewModel {
    
    var accountName: String {
        account.name
    }

    // This now uses the passed-in balance
    var currentBalanceFormatted: String {
        String(format: "£%.2f", balance)
    }

    var isCreditAccount: Bool {
        account.type.isCredit
    }

    // This now uses the passed-in balance
    var creditLimitUsage: Double? {
        guard let limit = account.creditLimit, limit > 0 else { return nil }
        return (balance / limit).clamped(to: 0...1)
    }

    var isBNPLAccount: Bool {
        account.type == .bnpl
    }
    
    // 'alertThreshold' was removed from the model. This logic is no longer valid.
    // We can re-introduce this feature later if needed.
    var alertThresholdHit: Bool {
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

// Helper extension remains the same
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
