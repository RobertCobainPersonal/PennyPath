//
//  AddAccountView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

// Views/Accounts/AddAccountView.swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/**
 * This view has been rebuilt to support all the new account types in the model.
 * It dynamically changes its input fields based on the selected account type,
 * providing a tailored data entry experience for the user.
 *
 * UPDATED: Now includes DatePickers for both opening balance and loan origination dates.
 */
struct AddAccountView: View {
    // MARK: - Environment & State
    @Environment(\.presentationMode) var presentationMode
    
    // --- General Information ---
    @State private var name: String = ""
    @State private var institution: String = ""
    @State private var uiAccountType: AccountUIType = .currentAccount
    
    // --- State for Financial Fields ---
    @State private var balanceStr: String = ""
    @State private var principalAmountStr: String = ""
    @State private var interestRateStr: String = ""
    @State private var creditLimitStr: String = ""
    @State private var apyStr: String = ""
    
    // --- State for Dates ---
    @State private var openingBalanceDate: Date = Date() // For transactional accounts
    @State private var originationDate: Date = Date() // For loan-style accounts
    
    // --- State for Type-Specific Fields ---
    @State private var isLender: Bool = false
    @State private var counterpartyStr: String = ""
    @State private var originalCreditorStr: String = ""
    @State private var settlementAmountStr: String = ""
    
    // --- Alerting ---
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // MARK: - View Body
    var body: some View {
        NavigationView {
            Form {
                // Section for common details across all account types.
                Section(header: Text("General Information")) {
                    Picker("Account Type", selection: $uiAccountType) {
                        ForEach(AccountUIType.allCases) { type in Text(type.rawValue).tag(type) }
                    }.pickerStyle(.menu)
                    
                    TextField(namePlaceholder, text: $name)
                    TextField(institutionPlaceholder, text: $institution)
                }
                
                // --- Dynamic Section ---
                Section(header: Text(detailsHeader)) {
                    switch uiAccountType {
                    case .currentAccount: currentAccountFields
                    case .savingsAccount: savingsAccountFields
                    case .creditCard: creditCardFields
                    case .loan: loanFields
                    case .bnpl: bnplFields
                    case .familyLoan: familyLoanFields
                    case .collectionAccount: collectionAccountFields
                    case .generic: genericFields
                    }
                }
                
                Section { Button("Save Account") { saveAccount() }.disabled(name.isEmpty) }
            }
            .navigationTitle("Add Account")
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Add Account"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - Dynamic UI Helpers & Field Sub-views
    
    private var namePlaceholder: String { /* ... unchanged ... */
        switch uiAccountType {
        case .currentAccount: return "e.g., Everyday Account"
        case .savingsAccount: return "e.g., Rainy Day Fund"
        case .familyLoan: return "e.g., Loan to David"
        default: return "e.g., Platinum Card, Car Loan"
        }
    }
    private var institutionPlaceholder: String { /* ... unchanged ... */
        switch uiAccountType {
        case .familyLoan: return "Lender/Borrower Name"
        case .collectionAccount: return "Collection Agency Name"
        default: return "e.g., HSBC, Klarna, Lloyds Bank"
        }
    }
    private var detailsHeader: String {
        switch uiAccountType {
        case .familyLoan, .loan, .bnpl: return "Loan Details"
        case .collectionAccount: return "Debt Details"
        case .currentAccount, .savingsAccount, .creditCard, .generic: return "Opening Balance"
        }
    }
    
    @ViewBuilder private var openingBalanceFields: some View {
        TextField("Balance as of date (£)", text: $balanceStr).keyboardType(.decimalPad)
        DatePicker("Date of balance", selection: $openingBalanceDate, displayedComponents: .date)
    }
    
    private var currentAccountFields: some View { openingBalanceFields }
    private var savingsAccountFields: some View { Group { openingBalanceFields; TextField("Interest Rate (AER) %", text: $apyStr).keyboardType(.decimalPad) } }
    private var creditCardFields: some View { Group { openingBalanceFields; TextField("Credit Limit (£)", text: $creditLimitStr).keyboardType(.decimalPad); TextField("Interest Rate (APR) %", text: $interestRateStr).keyboardType(.decimalPad) } }
    private var genericFields: some View { openingBalanceFields }

    // --- UPDATED: Loan-style accounts now include a DatePicker for origination date ---
    private var loanFields: some View {
        Group {
            TextField("Original Loan Amount (£)", text: $principalAmountStr).keyboardType(.decimalPad)
            TextField("Outstanding Balance (£)", text: $balanceStr).keyboardType(.decimalPad)
            DatePicker("Loan start date", selection: $originationDate, displayedComponents: .date)
            TextField("Interest Rate %", text: $interestRateStr).keyboardType(.decimalPad)
        }
    }
    
    private var bnplFields: some View {
        Group {
            TextField("Original Purchase Amount (£)", text: $principalAmountStr).keyboardType(.decimalPad)
            TextField("Outstanding Balance (£)", text: $balanceStr).keyboardType(.decimalPad)
            DatePicker("Purchase date", selection: $originationDate, displayedComponents: .date)
        }
    }
    
    private var familyLoanFields: some View {
        Group {
            Toggle(isOn: $isLender) { Text(isLender ? "I am the Lender" : "I am the Borrower") }
            TextField("Person's Name", text: $counterpartyStr)
            TextField("Original Amount (£)", text: $principalAmountStr).keyboardType(.decimalPad)
            TextField("Outstanding Balance (£)", text: $balanceStr).keyboardType(.decimalPad)
            DatePicker("Date of loan", selection: $originationDate, displayedComponents: .date)
        }
    }
    
    private var collectionAccountFields: some View {
        Group {
            TextField("Outstanding Balance (£)", text: $balanceStr).keyboardType(.decimalPad)
            DatePicker("Date assigned to agency", selection: $originationDate, displayedComponents: .date)
            TextField("Original Creditor (Optional)", text: $originalCreditorStr)
            TextField("Settlement Amount (Optional) (£)", text: $settlementAmountStr).keyboardType(.decimalPad)
        }
    }
    
    // MARK: - Firestore Logic
    private func saveAccount() {
        // ... validation and user ID logic is unchanged ...
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            presentAlert("Please enter a name for the account.")
            return
        }
        let finalInstitution = institution.isEmpty ? (uiAccountType == .familyLoan ? counterpartyStr : "N/A") : institution
        
        let detailsResult = buildDetails()
        
        let details: AccountDetails
        switch detailsResult {
        case .success(let accountDetails): details = accountDetails
        case .failure(let error): presentAlert(error.localizedDescription); return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            presentAlert("Could not find user. Please sign in again.")
            return
        }
        
        let newAccount = Account(name: name, institution: finalInstitution, currency: "GBP", details: details)
        
        saveToFirestore(account: newAccount, userId: userId)
    }
    
    /// UPDATED: This function now populates the new date fields in the model.
    private func buildDetails() -> Result<AccountDetails, Error> {
        func getDouble(_ string: String, fieldName: String) throws -> Double {
            guard let value = Double(string), value >= 0 else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid number for \(fieldName)."])
            }
            return value
        }
        
        do {
            let openingDateAsTimestamp = Timestamp(date: openingBalanceDate)
            let originationDateAsTimestamp = Timestamp(date: originationDate)

            switch uiAccountType {
            case .currentAccount:
                let balance = try getDouble(balanceStr, fieldName: "Opening Balance")
                return .success(.currentAccount(CurrentAccountDetails(openingBalance: balance, openingBalanceDate: openingDateAsTimestamp)))
                
            case .savingsAccount:
                let balance = try getDouble(balanceStr, fieldName: "Opening Balance")
                let apy = apyStr.isEmpty ? nil : try getDouble(apyStr, fieldName: "Interest Rate")
                return .success(.savingsAccount(SavingsAccountDetails(openingBalance: balance, openingBalanceDate: openingDateAsTimestamp, apy: apy)))
                
            case .creditCard:
                let balance = try getDouble(balanceStr, fieldName: "Opening Balance")
                let limit = try getDouble(creditLimitStr, fieldName: "Credit Limit")
                let apr = interestRateStr.isEmpty ? nil : try getDouble(interestRateStr, fieldName: "Interest Rate")
                return .success(.creditCard(CreditCardDetails(openingBalance: balance, openingBalanceDate: openingDateAsTimestamp, creditLimit: limit, apr: apr)))

            case .loan:
                let balance = try getDouble(balanceStr, fieldName: "Outstanding Balance")
                let principal = try getDouble(principalAmountStr, fieldName: "Original Amount")
                let rate = try getDouble(interestRateStr, fieldName: "Interest Rate")
                return .success(.loan(LoanDetails(originationDate: originationDateAsTimestamp, originalAmount: principal, outstandingBalance: balance, interestRate: rate, termInMonths: 0)))
            
            case .bnpl:
                let balance = try getDouble(balanceStr, fieldName: "Outstanding Balance")
                let principal = try getDouble(principalAmountStr, fieldName: "Original Amount")
                return .success(.bnpl(BNPLDetails(originationDate: originationDateAsTimestamp, originalPurchaseAmount: principal, outstandingBalance: balance, provider: institution, remainingInstallments: 0)))
            
            case .familyLoan:
                guard !counterpartyStr.isEmpty else { throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Please enter the name of the person."])}
                let balance = try getDouble(balanceStr, fieldName: "Outstanding Balance")
                let principal = try getDouble(principalAmountStr, fieldName: "Original Amount")
                return .success(.familyLoan(FamilyLoanDetails(loanDate: originationDateAsTimestamp, isLender: isLender, counterparty: counterpartyStr, originalAmount: principal, outstandingBalance: balance)))
            
            case .collectionAccount:
                let balance = try getDouble(balanceStr, fieldName: "Outstanding Balance")
                let settlement = settlementAmountStr.isEmpty ? nil : try getDouble(settlementAmountStr, fieldName: "Settlement Amount")
                return .success(.collectionAccount(CollectionAccountDetails(dateAssigned: originationDateAsTimestamp, agency: institution, originalCreditor: originalCreditorStr, outstandingBalance: balance, settlementAmount: settlement)))

            case .generic:
                let balance = try getDouble(balanceStr, fieldName: "Opening Balance")
                return .success(.generic(GenericDetails(openingBalance: balance, openingBalanceDate: openingDateAsTimestamp)))
            }
        } catch {
            return .failure(error)
        }
    }
    
    private func saveToFirestore(account: Account, userId: String) {
        // ... this function is unchanged ...
        let db = Firestore.firestore()
        let collectionPath = "users/\(userId)/accounts"
        
        do {
            try db.collection(collectionPath).addDocument(from: account) { error in
                if let error = error {
                    self.presentAlert("Error saving account: \(error.localizedDescription)")
                } else {
                    print("Account successfully saved!")
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        } catch {
            self.presentAlert("Failed to encode account data: \(error.localizedDescription)")
        }
    }
    
    private func presentAlert(_ message: String) { self.alertMessage = message; self.showAlert = true }
}


// MARK: - Preview Initializer & Provider
extension AddAccountView {
    init(
        name: String = "", institution: String = "", uiAccountType: AccountUIType = .currentAccount,
        balanceStr: String = "", principalAmountStr: String = "", interestRateStr: String = "",
        creditLimitStr: String = "", apyStr: String = "", openingBalanceDate: Date = Date(),
        originationDate: Date = Date(), isLender: Bool = false, counterpartyStr: String = "",
        originalCreditorStr: String = "", settlementAmountStr: String = ""
    ) {
        self._name = State(initialValue: name)
        self._institution = State(initialValue: institution)
        self._uiAccountType = State(initialValue: uiAccountType)
        self._balanceStr = State(initialValue: balanceStr)
        self._principalAmountStr = State(initialValue: principalAmountStr)
        self._interestRateStr = State(initialValue: interestRateStr)
        self._creditLimitStr = State(initialValue: creditLimitStr)
        self._apyStr = State(initialValue: apyStr)
        self._openingBalanceDate = State(initialValue: openingBalanceDate)
        self._originationDate = State(initialValue: originationDate)
        self._isLender = State(initialValue: isLender)
        self._counterpartyStr = State(initialValue: counterpartyStr)
        self._originalCreditorStr = State(initialValue: originalCreditorStr)
        self._settlementAmountStr = State(initialValue: settlementAmountStr)
    }
}

// Preview Provider remains the same, but would benefit from passing mock origination dates.
struct AddAccountView_Previews: PreviewProvider {
    static var previews: some View {
        // ... unchanged ...
        TabView {
            ForEach(AccountUIType.allCases) { type in
                mockView(for: type)
                    .tabItem { Label(type.rawValue, systemImage: icon(for: type)) }
                    .tag(type)
            }
        }
    }
    
    @ViewBuilder
    private static func mockView(for type: AccountUIType) -> some View {
        let lastFriday = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let threeYearsAgo = Calendar.current.date(byAdding: .year, value: -3, to: Date())!
        
        switch type {
        case .currentAccount:
            AddAccountView(name: "Current Account", institution: "HSBC", uiAccountType: .currentAccount, balanceStr: "1950.25", openingBalanceDate: lastFriday)
        case .savingsAccount:
            AddAccountView(name: "Easy Access Saver", institution: "Marcus", uiAccountType: .savingsAccount, balanceStr: "12500.00", apyStr: "4.75", openingBalanceDate: lastFriday)
        case .creditCard:
            AddAccountView(name: "Platinum Cashback Card", institution: "Amex", uiAccountType: .creditCard, balanceStr: "720.50", interestRateStr: "24.5", creditLimitStr: "8000", openingBalanceDate: lastFriday)
        case .loan:
            AddAccountView(name: "Car Loan", institution: "Lloyds Bank", uiAccountType: .loan, balanceStr: "8000.00", principalAmountStr: "15000", interestRateStr: "6.2", originationDate: threeYearsAgo)
        case .bnpl:
            AddAccountView(name: "ASOS Order", institution: "Klarna", uiAccountType: .bnpl, balanceStr: "89.99", principalAmountStr: "89.99", originationDate: lastFriday)
        case .familyLoan:
            AddAccountView(name: "Loan from Mum", institution: "Mum", uiAccountType: .familyLoan, balanceStr: "200.00", principalAmountStr: "200.00", originationDate: lastFriday, isLender: false, counterpartyStr: "Mum")
        case .collectionAccount:
            AddAccountView(name: "Old Vodafone Bill", institution: "Lowell Financial", uiAccountType: .collectionAccount, balanceStr: "150.00", originationDate: threeYearsAgo, originalCreditorStr: "Vodafone", settlementAmountStr: "90.00")
        case .generic:
            AddAccountView(name: "Monzo Pot", institution: "Monzo", uiAccountType: .generic, balanceStr: "250.00", openingBalanceDate: lastFriday)
        }
    }
    
    private static func icon(for type: AccountUIType) -> String { /* ... unchanged ... */
        switch type {
        case .currentAccount: return "sterlingsign.circle"
        case .savingsAccount: return "banknote"
        case .creditCard: return "creditcard"
        case .loan: return "doc.text"
        case .bnpl: return "tag"
        case .familyLoan: return "person.2"
        case .collectionAccount: return "exclamationmark.triangle"
        case .generic: return "questionmark.circle"
        }
    }
}
