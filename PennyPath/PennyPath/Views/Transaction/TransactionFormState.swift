//
//  TransactionFormState.swift
//  PennyPath
//
//  Created by Robert Cobain on 21/06/2025.
//

import SwiftUI

// MARK: - Transaction Form State Model

/// Centralized state for transaction forms (Add/Edit)
class TransactionFormState: ObservableObject {
    // Basic transaction fields
    @Published var amount: String = ""
    @Published var merchant: String = ""
    @Published var selectedAccountId: String = ""
    @Published var selectedToAccountId: String = "" // For transfers
    @Published var selectedCategoryId: String = ""
    @Published var selectedEventId: String = ""
    @Published var transactionDate = Date()
    @Published var transactionType: TransactionType = .expense
    @Published var isBusinessExpense = false
    
    // BNPL fields
    @Published var isBNPLPurchase = false
    @Published var bnplProvider = ""
    @Published var bnplPlan = ""
    @Published var paymentAccountId = ""
    @Published var upfrontFee = ""
    
    // UI state
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    // MARK: - Computed Properties
    
    /// Basic form validation for UI responsiveness (without AppStore access)
    var isFormValid: Bool {
        guard !amount.isEmpty,
              let amountValue = Double(amount),
              amountValue > 0,
              !merchant.isEmpty,
              !selectedAccountId.isEmpty else {
            return false
        }
        
        // Basic BNPL validation (without account type checking)
        if isBNPLPurchase {
            guard !bnplProvider.isEmpty,
                  !bnplPlan.isEmpty else {
                return false
            }
        }
        
        // Transfer validation
        if transactionType == .transfer {
            return !selectedToAccountId.isEmpty && selectedAccountId != selectedToAccountId
        }
        
        return true
    }
    
    // Initialize with existing transaction (for edit mode)
    init(transaction: Transaction? = nil) {
        if let transaction = transaction {
            populateFromTransaction(transaction)
        }
    }
    
    private func populateFromTransaction(_ transaction: Transaction) {
        self.amount = String(format: "%.2f", abs(transaction.amount))
        self.merchant = transaction.description
        self.selectedAccountId = transaction.accountId
        self.selectedCategoryId = transaction.categoryId ?? ""
        self.selectedEventId = transaction.eventId ?? ""
        self.transactionDate = transaction.date
        
        // Determine transaction type
        if transaction.categoryId == nil {
            self.transactionType = .transfer
        } else {
            self.transactionType = transaction.amount >= 0 ? .income : .expense
        }
        
        // TODO: Detect and populate BNPL fields from transaction
    }
    
    func clearBNPLFields() {
        bnplProvider = ""
        bnplPlan = ""
        paymentAccountId = ""
        upfrontFee = ""
    }
}

// MARK: - Transaction Type Toggle Component

struct TransactionTypeToggleSection: View {
    @ObservedObject var formState: TransactionFormState
    let isEditMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transaction Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isEditMode {
                // Show type as read-only in edit mode
                HStack {
                    Image(systemName: transactionTypeIcon)
                        .foregroundColor(transactionTypeColor)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transactionTypeDisplayText)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text("Transaction type cannot be changed when editing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            } else {
                // Editable picker for add mode
                Picker("Type", selection: $formState.transactionType) {
                    Text("💸 Expense").tag(TransactionType.expense)
                    Text("💰 Income").tag(TransactionType.income)
                    Text("🔄 Transfer").tag(TransactionType.transfer)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: formState.transactionType) { _ in
                    // Clear relevant fields when switching types
                    formState.selectedCategoryId = ""
                    formState.selectedToAccountId = ""
                    formState.isBusinessExpense = false
                    formState.isBNPLPurchase = false
                    formState.clearBNPLFields()
                    formState.merchant = ""
                }
            }
        }
    }
    
    private var transactionTypeIcon: String {
        switch formState.transactionType {
        case .income: return "arrow.down.circle"
        case .expense: return "arrow.up.circle"
        case .transfer: return "arrow.left.arrow.right.circle"
        }
    }
    
    private var transactionTypeColor: Color {
        switch formState.transactionType {
        case .income: return .green
        case .expense: return .blue
        case .transfer: return .orange
        }
    }
    
    private var transactionTypeDisplayText: String {
        switch formState.transactionType {
        case .income: return "💰 Income"
        case .expense: return "💸 Expense"
        case .transfer: return "🔄 Transfer"
        }
    }
}

// MARK: - Amount Entry Component

struct AmountEntrySection: View {
    @ObservedObject var formState: TransactionFormState
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formState.transactionType == .transfer ? "Transfer Amount" : "Amount")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("£")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $formState.amount)
                    .font(.title2)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: formState.amount) { newValue in
                        formState.amount = formatAmountInput(newValue)
                    }
                
                Spacer()
                
                Button(action: {
                    // TODO: Add calculator functionality
                }) {
                    Image(systemName: "plus.forwardslash.minus")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private func formatAmountInput(_ input: String) -> String {
        let filtered = input.filter { $0.isNumber || $0 == "." }
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1]
        }
        if components.count == 2 && components[1].count > 2 {
            return components[0] + "." + String(components[1].prefix(2))
        }
        return filtered
    }
}

// MARK: - Quick Amounts Component

struct QuickAmountsSection: View {
    @ObservedObject var formState: TransactionFormState
    
    var body: some View {
        QuickAmountButtons(
            selectedAmount: $formState.amount,
            amounts: formState.transactionType == .income ?
                QuickAmountPresets.bills : QuickAmountPresets.standard
        )
    }
}


// MARK: - Transfer Accounts Component

struct TransferAccountsSection: View {
    @ObservedObject var formState: TransactionFormState
    
    var body: some View {
        VStack(spacing: 16) {
            TransferAccountPicker(
                fromAccountId: $formState.selectedAccountId,
                toAccountId: $formState.selectedToAccountId,
                label: "From Account",
                isDestination: false
            )
            
            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            TransferAccountPicker(
                fromAccountId: $formState.selectedAccountId,
                toAccountId: $formState.selectedToAccountId,
                label: "To Account",
                isDestination: true
            )
        }
    }
}

// MARK: - Merchant Entry Component

struct MerchantEntrySection: View {
    @ObservedObject var formState: TransactionFormState
    @FocusState private var isMerchantFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(contextualMerchantLabel)
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField(contextualMerchantPlaceholder, text: $formState.merchant)
                .focused($isMerchantFocused)
                .textInputAutocapitalization(.words)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            
            if !formState.merchant.isEmpty && isMerchantFocused && formState.transactionType != .transfer {
                contextualSuggestions
            }
        }
    }
    
    private var contextualMerchantLabel: String {
        switch formState.transactionType {
        case .income: return "Income Source"
        case .expense: return "Merchant/Store"
        case .transfer: return "Description"
        }
    }
    
    private var contextualMerchantPlaceholder: String {
        switch formState.transactionType {
        case .income: return "Where is the money from?"
        case .expense: return "Where did you spend?"
        case .transfer: return "Transfer description"
        }
    }
    
    private var contextualSuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggestions")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(filteredSuggestions, id: \.self) { suggestion in
                    Button(action: {
                        formState.merchant = suggestion
                        isMerchantFocused = false
                        if formState.transactionType == .expense {
                            suggestCategoryFor(merchant: suggestion)
                        }
                    }) {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var filteredSuggestions: [String] {
        if formState.merchant.count < 2 { return [] }
        
        let suggestions = formState.transactionType == .income ? incomeSuggestions : expenseSuggestions
        return suggestions.filter {
            $0.localizedCaseInsensitiveContains(formState.merchant)
        }.prefix(6).map { $0 }
    }
    
    private var incomeSuggestions: [String] {
        return [
            "Acme Corp Ltd", "Freelance Client", "Investment Dividend",
            "Rental Property", "Side Project", "Cashback Reward",
            "Gift", "Tax Refund", "Bonus Payment", "Commission"
        ]
    }
    
    private var expenseSuggestions: [String] {
        return [
            "Tesco", "Sainsbury's", "ASDA", "Morrisons", "M&S",
            "Pret A Manger", "Costa Coffee", "Starbucks", "McDonald's",
            "Shell", "BP", "Esso", "Vue Cinema", "Spotify", "Netflix"
        ]
    }
    
    private func suggestCategoryFor(merchant: String) {
        let merchantCategories: [String: String] = [
            "Tesco": "cat-shopping",
            "Sainsbury's": "cat-shopping",
            "ASDA": "cat-shopping",
            "Morrisons": "cat-shopping",
            "Pret A Manger": "cat-food",
            "Costa Coffee": "cat-food",
            "Starbucks": "cat-food",
            "McDonald's": "cat-food",
            "Shell": "cat-transport",
            "BP": "cat-transport",
            "Esso": "cat-transport",
            "Vue Cinema": "cat-entertainment",
            "Spotify": "cat-subscriptions",
            "Netflix": "cat-subscriptions"
        ]
        
        if let categoryId = merchantCategories[merchant] {
            formState.selectedCategoryId = categoryId
        }
    }
}

// MARK: - Category Selection Component

struct CategorySelectionSection: View {
    @ObservedObject var formState: TransactionFormState
    
    var body: some View {
        CategorySelectionView(
            selectedCategoryId: $formState.selectedCategoryId,
            transactionType: formState.transactionType
        )
    }
}

// MARK: - Event Selection Component

struct EventSelectionSection: View {
    @ObservedObject var formState: TransactionFormState
    
    var body: some View {
        EventPickerWithHeader(
            selectedEventId: $formState.selectedEventId,
            subtitle: "Group transactions by trips, projects, or occasions"
        )
    }
}

// MARK: - Business Expense Component

struct BusinessExpenseSection: View {
    @ObservedObject var formState: TransactionFormState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Business Expense")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Track for tax purposes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $formState.isBusinessExpense)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            if formState.isBusinessExpense {
                receiptUploadSection
            }
        }
    }
    
    private var receiptUploadSection: some View {
        HStack {
            Image(systemName: "camera")
                .foregroundColor(.blue)
            
            Text("Add Receipt")
                .foregroundColor(.blue)
            
            Spacer()
            
            Text("Optional")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .onTapGesture {
            print("📸 Receipt upload tapped")
        }
    }
}

// MARK: - Date Selection Component

struct DateSelectionSection: View {
    @ObservedObject var formState: TransactionFormState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date")
                .font(.headline)
                .fontWeight(.semibold)
            
            DatePicker("Transaction Date", selection: $formState.transactionDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
    }
}

// MARK: - Form Validation Helper

extension TransactionFormState {
    func isFormValid(appStore: AppStore) -> Bool {
        guard !amount.isEmpty,
              let amountValue = Double(amount),
              amountValue > 0,
              !merchant.isEmpty,
              !selectedAccountId.isEmpty else {
            return false
        }
        
        // BNPL-specific validation
        if isBNPLPurchase {
            // Must have BNPL account selected
            guard let account = appStore.accounts.first(where: { $0.id == selectedAccountId }),
                  account.type == .bnpl else {
                return false
            }
            
            // Must have BNPL provider and plan
            guard !bnplProvider.isEmpty,
                  !bnplPlan.isEmpty else {
                return false
            }
        }
        
        // Transfer validation
        if transactionType == .transfer {
            return !selectedToAccountId.isEmpty && selectedAccountId != selectedToAccountId
        }
        
        return true
    }
}

// MARK: - Preview Provider
struct TransactionFormComponents_Previews: PreviewProvider {
    static var previews: some View {
        let formState = TransactionFormState()
        
        ScrollView {
            VStack(spacing: 20) {
                TransactionTypeToggleSection(formState: formState, isEditMode: false)
                AmountEntrySection(formState: formState)
                AccountSelectionSection(formState: formState)
                MerchantEntrySection(formState: formState)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .environmentObject(AppStore())
    }
}
