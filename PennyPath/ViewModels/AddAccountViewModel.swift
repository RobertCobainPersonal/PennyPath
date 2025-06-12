//
//  AddAccountViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AddAccountViewModel: ObservableObject {
    
    // MARK: - Form Input Fields
    @Published var name: String = ""
    @Published var institution: String = ""
    @Published var type: AccountType = .currentAccount
    
    @Published var currentBalanceStr: String = ""
    @Published var openingBalanceStr: String = ""
    @Published var outstandingBalanceStr: String = ""
    @Published var creditLimitStr: String = ""
    @Published var aprStr: String = ""
    @Published var originalAmountStr: String = ""
    @Published var interestRateStr: String = ""
    
    @Published var counterpartyStr: String = ""
    @Published var originalCreditorStr: String = ""
    @Published var settlementAmountStr: String = ""

    @Published var openingBalanceDate: Date = Date()
    @Published var originationDate: Date = Date()
    
    // MARK: - State Management
    @Published var isLoading = false
    @Published var alertMessage: String?

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !institution.trimmingCharacters(in: .whitespaces).isEmpty &&
        !currentBalanceStr.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Firestore Logic (Refactored to use AccountService)
    
    func saveAccount() async {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields: Name, Institution, and Current Balance."
            return
        }
        
        isLoading = true

        func toDouble(_ string: String?) -> Double? {
            guard let string = string, !string.isEmpty else { return nil }
            return Double(string)
        }

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
            originationDate: originalAmountStr.isEmpty ? nil : Timestamp(date: originationDate),
            counterparty: counterpartyStr.isEmpty ? nil : counterpartyStr,
            originalCreditor: originalCreditorStr.isEmpty ? nil : originalCreditorStr,
            settlementAmount: toDouble(settlementAmountStr)
        )
        
        if type == .bnpl {
            newAccount.isBNPL = true
            newAccount.outstandingBalance = toDouble(outstandingBalanceStr)
        }

        // --- Use the new AccountService ---
        do {
            try await AccountService.shared.saveAccount(newAccount)
            print("Account successfully saved via AccountService!")
            alertMessage = "Account saved successfully!"
        } catch {
            print("Error saving account: \(error.localizedDescription)")
            alertMessage = "Error saving account: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
