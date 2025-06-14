//
//  AddIncomeViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AddIncomeViewModel: ObservableObject {
    @Published var amountStr: String = ""
    @Published var selectedAccountId: String = ""
    @Published var date: Date = Date()
    @Published var description: String = ""
    
    // --- Properties to handle editing ---
    private var transactionToEdit: Transaction?
    var navigationTitle: String {
        transactionToEdit == nil ? "New Income" : "Edit Income"
    }
    var saveButtonText: String {
        transactionToEdit == nil ? "Save Income" : "Update Income"
    }
    
    var isEditing: Bool {
        transactionToEdit != nil
    }

    var isFormValid: Bool {
        !amountStr.isEmpty && !selectedAccountId.isEmpty
    }
    
    // --- Initializers ---
    
    // Default initializer for adding new income
    init() {
        self.transactionToEdit = nil
    }
    
    // Initializer for editing existing income
    init(transactionToEdit: Transaction) {
        self.transactionToEdit = transactionToEdit
        
        // Pre-populate fields
        self.amountStr = String(transactionToEdit.amount)
        self.selectedAccountId = transactionToEdit.accountId
        self.date = transactionToEdit.date.dateValue()
        self.description = transactionToEdit.description
    }

    func saveOrUpdate() async throws {
        guard let userId = Auth.auth().currentUser?.uid, let amount = Double(amountStr) else {
            throw NSError(domain: "AddIncomeViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid data."])
        }

        if var transaction = transactionToEdit {
            // --- UPDATE LOGIC ---
            transaction.amount = abs(amount) // Ensure amount is positive
            transaction.accountId = selectedAccountId
            transaction.date = Timestamp(date: date)
            transaction.description = description
            
            try await TransactionService.shared.updateTransaction(transaction)
            
        } else {
            // --- SAVE NEW LOGIC ---
            let details = TransactionDetails(
                amount: amount,
                accountId: selectedAccountId,
                date: date,
                description: description,
                categoryId: nil, // Income does not have a category
                isBNPL: false,
                bnplPlan: nil,
                bnplFundingAccountId: nil,
                bnplSchedule: nil
            )
            try await TransactionService.shared.addTransaction(details: details, for: userId)
        }
    }
}
