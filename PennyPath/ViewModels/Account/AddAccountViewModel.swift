//
//  AddAccountViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: This ViewModel now supports both creating a new account and
//  editing an existing one.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AddAccountViewModel: ObservableObject, Identifiable {
    
    // --- Published properties for the form fields ---
    @Published var name: String = ""
    @Published var institution: String = ""
    @Published var type: AccountType = .currentAccount
    @Published var initialBalanceStr: String = ""
    @Published var dateOfBalance: Date = Date()
    
    // (Other specific fields)
    @Published var creditLimitStr: String = ""
    @Published var aprStr: String = ""
    @Published var originalAmountStr: String = ""
    @Published var interestRateStr: String = ""
    @Published var counterpartyStr: String = ""
    @Published var originalCreditorStr: String = ""
    @Published var settlementAmountStr: String = ""
    @Published var originationDate: Date = Date()
    
    // --- State Management ---
    @Published var isLoading = false
    @Published var alertMessage: String?
    
    // --- NEW: Properties to handle editing ---
    private var accountToEdit: Account?
        var navigationTitle: String {
            accountToEdit == nil ? "Add New Account" : "Edit Account"
        }
        var saveButtonText: String {
            accountToEdit == nil ? "Save Account" : "Update Account"
        }
        
        // 2. ADD THIS COMPUTED PROPERTY
        var id: String {
            accountToEdit?.id ?? UUID().uuidString
        }
    
    // --- Initializers ---
    
    // Default initializer for creating a new account
    init() {
        self.accountToEdit = nil
    }
    
    // NEW: Initializer for editing an existing account
    init(accountToEdit: Account) {
        self.accountToEdit = accountToEdit
        
        // Pre-populate all the fields from the existing account's data
        self.name = accountToEdit.name
        self.institution = accountToEdit.institution
        self.type = accountToEdit.type
        self.initialBalanceStr = String(accountToEdit.anchorBalance)
        self.dateOfBalance = accountToEdit.anchorDate.dateValue()
        
        // (Pre-populate other fields if they exist)
        self.creditLimitStr = accountToEdit.creditLimit.map { String($0) } ?? ""
        self.aprStr = accountToEdit.apr.map { String($0) } ?? ""
        self.originalAmountStr = accountToEdit.originalAmount.map { String($0) } ?? ""
        self.interestRateStr = accountToEdit.interestRate.map { String($0) } ?? ""
        self.counterpartyStr = accountToEdit.counterparty ?? ""
        self.originalCreditorStr = accountToEdit.originalCreditor ?? ""
        self.settlementAmountStr = accountToEdit.settlementAmount.map { String($0) } ?? ""
        self.originationDate = accountToEdit.originationDate?.dateValue() ?? Date()
    }
    

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !initialBalanceStr.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // UPDATED: This function now handles both saving and updating
    func saveOrUpdateAccount() async {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields: Name and Initial Balance."
            return
        }
        
        isLoading = true

        func toDouble(_ string: String?) -> Double? {
            guard let string = string, !string.isEmpty else { return nil }
            return Double(string)
        }

        // Use the existing account object if we are editing, or create a new one
        var account = self.accountToEdit ?? Account(name: "", type: .currentAccount, institution: "", anchorBalance: 0, anchorDate: Timestamp())
        
        // Update the account object with the new data from the form
        account.name = name
        account.type = type
        account.institution = institution
        account.anchorBalance = toDouble(initialBalanceStr) ?? 0.0
        account.anchorDate = Timestamp(date: dateOfBalance)
        account.lastUpdated = Timestamp(date: Date()) // Update the timestamp
        
        // (Update other fields)
        account.creditLimit = toDouble(creditLimitStr)
        account.apr = toDouble(aprStr)
        account.originalAmount = toDouble(originalAmountStr)
        account.interestRate = toDouble(interestRateStr)
        account.originationDate = type == .loan || type == .familyLoan ? Timestamp(date: originationDate) : nil
        account.counterparty = counterpartyStr.isEmpty ? nil : counterpartyStr
        account.originalCreditor = originalCreditorStr.isEmpty ? nil : originalCreditorStr
        account.settlementAmount = toDouble(settlementAmountStr)


        do {
            // If we are editing, call the update service, otherwise call the save service
            if accountToEdit != nil {
                try await AccountService.shared.updateAccount(account)
                alertMessage = "Account updated successfully!"
            } else {
                try await AccountService.shared.saveAccount(account)
                alertMessage = "Account saved successfully!"
            }
        } catch {
            print("Error saving or updating account: \(error.localizedDescription)")
            alertMessage = "Error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
