//
//  EditTransactionView.swift
//  PennyPath
//
//  Created by Robert Cobain on 18/06/2025.
//

import SwiftUI

struct EditTransactionView: View {
    @EnvironmentObject var appStore: AppStore
    @Environment(\.dismiss) private var dismiss
    
    let originalTransaction: Transaction
    
    // MARK: - Form State
    @State private var amount: String
    @State private var merchant: String
    @State private var selectedAccountId: String
    @State private var selectedToAccountId: String = "" // For transfers
    @State private var selectedCategoryId: String
    @State private var selectedEventId: String
    @State private var transactionDate: Date
    @State private var transactionType: TransactionType
    @State private var isBusinessExpense: Bool = false
    @State private var isScheduled: Bool
    @State private var recurrence: RecurrenceType?
    
    // MARK: - UI State
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isMerchantFocused: Bool
    
    init(transaction: Transaction) {
        self.originalTransaction = transaction
        
        // Initialize form state with existing transaction data
        self._amount = State(initialValue: String(format: "%.2f", abs(transaction.amount)))
        self._merchant = State(initialValue: transaction.description)
        self._selectedAccountId = State(initialValue: transaction.accountId)
        self._selectedCategoryId = State(initialValue: transaction.categoryId ?? "")
        self._selectedEventId = State(initialValue: transaction.eventId ?? "")
        self._transactionDate = State(initialValue: transaction.date)
        self._isScheduled = State(initialValue: transaction.isScheduled)
        self._recurrence = State(initialValue: transaction.recurrence)
        
        // Determine transaction type
        if transaction.categoryId == nil {
            self._transactionType = State(initialValue: .transfer)
        } else {
            self._transactionType = State(initialValue: transaction.amount >= 0 ? .income : .expense)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Transaction Type Toggle (disabled for existing transactions)
                    transactionTypeDisplay
                    
                    // Amount Entry Section
                    amountEntrySection
                    
                    // Quick Amounts (only for income/expense)
                    if transactionType != .transfer {
                        quickAmountsSection
                    }
                    
                    // Account Selection (different for transfers)
                    if transactionType == .transfer {
                        transferAccountsSection
                    } else {
                        accountSelectionSection
                    }
                    
                    // Merchant/Source/Description Section
                    merchantSection
                    
                    // Category Selection (not for transfers)
                    if transactionType != .transfer {
                        categorySelectionSection
                    }
                    
                    // Event Selection (for all transaction types)
                    eventSelectionSection
                    
                    // Business Expense Toggle (only for expenses)
                    if transactionType == .expense {
                        businessExpenseSection
                    }
                    
                    // Scheduled Transaction Settings
                    scheduledTransactionSection
                    
                    // Date Selection
                    dateSelectionSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || isLoading)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Components
    
    private var transactionTypeDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transaction Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: transactionTypeIcon)
                    .foregroundColor(transactionTypeColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transactionType == .transfer ? "🔄 Transfer" :
                         transactionType == .income ? "💰 Income" : "💸 Expense")
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
        }
    }
    
    private var amountEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(transactionType == .transfer ? "Transfer Amount" : "Amount")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("£")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $amount)
                    .font(.title2)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: amount) { newValue in
                        amount = formatAmountInput(newValue)
                    }
                
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var quickAmountsSection: some View {
        QuickAmountButtons(
            selectedAmount: $amount,
            amounts: transactionType == .income ?
                QuickAmountPresets.bills : QuickAmountPresets.standard
        )
    }
    
    private var transferAccountsSection: some View {
        VStack(spacing: 16) {
            // From Account
            TransferAccountPicker(
                fromAccountId: $selectedAccountId,
                toAccountId: $selectedToAccountId,
                label: "From Account",
                isDestination: false
            )
            
            // Transfer direction indicator
            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            // To Account
            TransferAccountPicker(
                fromAccountId: $selectedAccountId,
                toAccountId: $selectedToAccountId,
                label: "To Account",
                isDestination: true
            )
        }
    }
    
    private var accountSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.headline)
                .fontWeight(.semibold)
            
            AccountPicker(
                selectedAccountId: $selectedAccountId,
                placeholder: "Select Account",
                showBalance: true
            )
        }
    }
    
    private var merchantSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(contextualMerchantLabel)
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField(contextualMerchantPlaceholder, text: $merchant)
                .focused($isMerchantFocused)
                .textInputAutocapitalization(.words)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
    }
    
    private var categorySelectionSection: some View {
        CategorySelectionView(
            selectedCategoryId: $selectedCategoryId,
            transactionType: transactionType
        )
    }
    
    private var eventSelectionSection: some View {
        EventPickerWithHeader(
            selectedEventId: $selectedEventId,
            subtitle: "Group transactions by trips, projects, or occasions"
        )
    }
    
    private var businessExpenseSection: some View {
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
                
                Toggle("", isOn: $isBusinessExpense)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var scheduledTransactionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scheduled Transaction")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recurring Payment")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Set up automatic recurring payments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isScheduled)
                }
                
                if isScheduled {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recurrence")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Recurrence", selection: Binding(
                            get: { recurrence ?? .monthly },
                            set: { recurrence = $0 }
                        )) {
                            ForEach(RecurrenceType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date")
                .font(.headline)
                .fontWeight(.semibold)
            
            DatePicker("Transaction Date", selection: $transactionDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        guard !amount.isEmpty,
              let amountValue = Double(amount),
              amountValue > 0,
              !merchant.isEmpty,
              !selectedAccountId.isEmpty else {
            return false
        }
        
        // Additional validation for transfers
        if transactionType == .transfer {
            return !selectedToAccountId.isEmpty && selectedAccountId != selectedToAccountId
        }
        
        return true
    }
    
    private var contextualMerchantLabel: String {
        switch transactionType {
        case .income: return "Income Source"
        case .expense: return "Merchant/Store"
        case .transfer: return "Description"
        }
    }
    
    private var contextualMerchantPlaceholder: String {
        switch transactionType {
        case .income: return "Where is the money from?"
        case .expense: return "Where did you spend?"
        case .transfer: return "Transfer description"
        }
    }
    
    private var transactionTypeIcon: String {
        switch transactionType {
        case .income: return "arrow.down.circle"
        case .expense: return "arrow.up.circle"
        case .transfer: return "arrow.left.arrow.right.circle"
        }
    }
    
    private var transactionTypeColor: Color {
        switch transactionType {
        case .income: return .green
        case .expense: return .blue
        case .transfer: return .orange
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func saveTransaction() {
        guard isFormValid else { return }
        
        isLoading = true
        
        // Calculate the amount difference for account balance adjustment
        let oldAmount = originalTransaction.amount
        let newAmount = (Double(amount) ?? 0) * (transactionType == .income ? 1 : -1)
        let amountDifference = newAmount - oldAmount
        
        // Create updated transaction
        let updatedTransaction = Transaction(
            id: originalTransaction.id,
            userId: originalTransaction.userId,
            accountId: selectedAccountId,
            categoryId: selectedCategoryId.isEmpty ? nil : selectedCategoryId,
            bnplPlanId: originalTransaction.bnplPlanId,
            eventId: selectedEventId.isEmpty ? nil : selectedEventId,
            amount: newAmount,
            description: merchant,
            date: transactionDate,
            isScheduled: isScheduled,
            recurrence: isScheduled ? recurrence : nil
        )
        
        // Update transaction in AppStore
        if let index = appStore.transactions.firstIndex(where: { $0.id == originalTransaction.id }) {
            appStore.transactions[index] = updatedTransaction
        }
        
        // Update account balances if account changed or amount changed
        if selectedAccountId != originalTransaction.accountId {
            // Account changed - reverse old amount from old account, add new amount to new account
            if let oldAccountIndex = appStore.accounts.firstIndex(where: { $0.id == originalTransaction.accountId }) {
                appStore.accounts[oldAccountIndex].balance -= oldAmount
            }
            
            if let newAccountIndex = appStore.accounts.firstIndex(where: { $0.id == selectedAccountId }) {
                appStore.accounts[newAccountIndex].balance += newAmount
            }
        } else {
            // Same account - just adjust by the difference
            if let accountIndex = appStore.accounts.firstIndex(where: { $0.id == selectedAccountId }) {
                appStore.accounts[accountIndex].balance += amountDifference
            }
        }
        
        // Success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("✏️ Transaction updated: \(merchant) - £\(abs(newAmount))")
        
        isLoading = false
        dismiss()
    }
}

// MARK: - Preview Provider
struct EditTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        EditTransactionView(
            transaction: Transaction(
                userId: "test",
                accountId: "acc-current",
                categoryId: "cat-food",
                eventId: "event-paris",
                amount: -45.80,
                description: "Café de Flore"
            )
        )
        .environmentObject(AppStore())
    }
}
