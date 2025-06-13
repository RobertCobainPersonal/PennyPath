//
//  AddAccountViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: This ViewModel has been updated to support the new
//  'anchorBalance' architecture.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AddAccountViewModel: ObservableObject {
    
    // The UI will now only ask for one balance.
    // We'll call it 'initialBalanceStr' for clarity.
    @Published var name: String = ""
    @Published var institution: String = ""
    @Published var type: AccountType = .currentAccount
    @Published var initialBalanceStr: String = ""
    @Published var dateOfBalance: Date = Date()
    
    // These properties remain for credit-specific accounts etc.
    @Published var creditLimitStr: String = ""
    @Published var aprStr: String = ""
    @Published var originalAmountStr: String = ""
    @Published var interestRateStr: String = ""
    @Published var counterpartyStr: String = ""
    @Published var originalCreditorStr: String = ""
    @Published var settlementAmountStr: String = ""
    @Published var originationDate: Date = Date()
    
    @Published var isLoading = false
    @Published var alertMessage: String?

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !initialBalanceStr.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func saveAccount() async {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields: Name and Initial Balance."
            return
        }
        
        isLoading = true

        func toDouble(_ string: String?) -> Double? {
            guard let string = string, !string.isEmpty else { return nil }
            return Double(string)
        }

        // Create the new Account object using the 'anchor' properties
        var newAccount = Account(
            name: name,
            type: type,
            institution: institution,
            anchorBalance: toDouble(initialBalanceStr) ?? 0.0,
            anchorDate: Timestamp(date: dateOfBalance),
            isBNPL: type == .bnpl ? true : nil,
            creditLimit: toDouble(creditLimitStr),
            apr: toDouble(aprStr),
            originalAmount: toDouble(originalAmountStr),
            interestRate: toDouble(interestRateStr),
            originationDate: type == .loan || type == .familyLoan ? Timestamp(date: originationDate) : nil,
            counterparty: counterpartyStr.isEmpty ? nil : counterpartyStr,
            originalCreditor: originalCreditorStr.isEmpty ? nil : originalCreditorStr,
            settlementAmount: toDouble(settlementAmountStr)
        )

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
