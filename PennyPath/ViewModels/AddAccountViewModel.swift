//
//  AddAccountViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: This ViewModel supports the new "flat" Account model.
//  It holds all form state and contains the logic to construct and
//  save the simplified Account object to Firestore.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AddAccountViewModel: ObservableObject {
    
    // MARK: - Form Input Fields
    @Published var name: String = ""
    @Published var institution: String = ""
    @Published var type: AccountType = .checking
    
    // Using strings for text fields to handle user input gracefully
    @Published var currentBalanceStr: String = ""
    @Published var openingBalanceStr: String = ""
    @Published var outstandingBalanceStr: String = ""
    @Published var creditLimitStr: String = ""
    @Published var aprStr: String = ""
    @Published var originalAmountStr: String = ""
    @Published var interestRateStr: String = ""
    
    // Date properties
    @Published var openingBalanceDate: Date = Date()
    @Published var originationDate: Date = Date()
    
    // MARK: - State Management
    @Published var isLoading = false
    @Published var alertMessage: String?

    // Computed property to check if the form is valid for saving
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !institution.trimmingCharacters(in: .whitespaces).isEmpty &&
        !currentBalanceStr.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Firestore Logic
    
    func saveAccount() async {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields: Name, Institution, and Current Balance."
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "You must be logged in to save an account."
            return
        }

        isLoading = true

        // Helper to safely convert string to double
        func toDouble(_ string: String?) -> Double? {
            guard let string = string, !string.isEmpty else { return nil }
            return Double(string)
        }

        // Construct the new, flat Account object
        var newAccount = Account(
            name: name,
            type: type,
            institution: institution,
            currentBalance: toDouble(currentBalanceStr) ?? 0.0,
            openingBalance: toDouble(openingBalanceStr),
            openingBalanceDate: openingBalanceStr.isEmpty ? nil : Timestamp(date: openingBalanceDate),
            creditLimit: toDouble(creditLimitStr),
            apr: toDouble(aprStr),
            originalAmount: toDouble(originalAmountStr),
            interestRate: toDouble(interestRateStr),
            originationDate: originalAmountStr.isEmpty ? nil : Timestamp(date: originationDate)
        )
        
        // Add BNPL-specific fields if applicable
        if type == .bnpl {
            newAccount.isBNPL = true
            newAccount.outstandingBalance = toDouble(outstandingBalanceStr)
        }

        // --- Save to Firestore ---
        let db = Firestore.firestore()
        let collectionPath = "users/\(userId)/accounts"

        do {
            try db.collection(collectionPath).addDocument(from: newAccount)
            print("Account successfully saved!")
            alertMessage = "Account saved successfully!"
        } catch {
            print("Error saving account: \(error.localizedDescription)")
            alertMessage = "Error saving account: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}