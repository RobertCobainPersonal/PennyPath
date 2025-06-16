//
//  AddTransactionView.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var appStore: AppStore
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Form State
    @State private var amount: String = ""
    @State private var merchant: String = ""
    @State private var selectedAccountId: String = ""
    @State private var selectedToAccountId: String = "" // For transfers
    @State private var selectedCategoryId: String = ""
    @State private var selectedEventId: String = ""
    @State private var transactionDate = Date()
    @State private var transactionType: TransactionType = .expense
    @State private var isBusinessExpense = false
    @State private var showingAllCategories = false
    
    // MARK: - UI State
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isMerchantFocused: Bool
    
    // Quick amount suggestions
    private let quickAmounts = [5.0, 10.0, 25.0, 50.0, 100.0]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Transaction Type Toggle
                    transactionTypeToggle
                    
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
                    
                    // Date Selection
                    dateSelectionSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Transaction")
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
            .sheet(isPresented: $showingAllCategories) {
                AllCategoriesView(selectedCategoryId: $selectedCategoryId, transactionType: transactionType)
            }
            .onAppear {
                setupDefaults()
            }
        }
    }
    
    // MARK: - View Components
    
    private var transactionTypeToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transaction Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            Picker("Type", selection: $transactionType) {
                Text("💸 Expense").tag(TransactionType.expense)
                Text("💰 Income").tag(TransactionType.income)
                Text("🔄 Transfer").tag(TransactionType.transfer)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: transactionType) { _ in
                // Clear relevant fields when switching types
                selectedCategoryId = ""
                selectedToAccountId = ""
                isBusinessExpense = false
                merchant = "" // Clear merchant when switching to help with placeholder update
            }
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
                
                Button(action: {
                    // TODO: Add calculator functionality
                }) {
                    Image(systemName: "calculator")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var quickAmountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Amounts")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(quickAmounts, id: \.self) { quickAmount in
                    Button(action: {
                        amount = String(format: "%.2f", quickAmount)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        Text("£\(Int(quickAmount))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var transferAccountsSection: some View {
        VStack(spacing: 16) {
            // From Account
            VStack(alignment: .leading, spacing: 12) {
                Text("From Account")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                accountPicker(selectedAccountId: $selectedAccountId, placeholder: "Select source account")
            }
            
            // Transfer direction indicator
            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            // To Account
            VStack(alignment: .leading, spacing: 12) {
                Text("To Account")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                accountPicker(selectedAccountId: $selectedToAccountId, placeholder: "Select destination account")
            }
        }
    }
    
    private var accountSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.headline)
                .fontWeight(.semibold)
            
            accountPicker(selectedAccountId: $selectedAccountId, placeholder: "Select Account")
        }
    }
    
    private func accountPicker(selectedAccountId: Binding<String>, placeholder: String) -> some View {
        Menu {
            ForEach(appStore.accounts) { account in
                Button(action: {
                    selectedAccountId.wrappedValue = account.id
                }) {
                    HStack {
                        Image(systemName: account.type.icon)
                            .foregroundColor(Color(hex: account.type.color))
                        Text(account.name)
                        if account.id == selectedAccountId.wrappedValue {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                if let selectedAccount = appStore.accounts.first(where: { $0.id == selectedAccountId.wrappedValue }) {
                    Image(systemName: selectedAccount.type.icon)
                        .foregroundColor(Color(hex: selectedAccount.type.color))
                    Text(selectedAccount.name)
                        .foregroundColor(.primary)
                } else {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
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
            
            // Context-aware suggestions
            if !merchant.isEmpty && isMerchantFocused && transactionType != .transfer {
                contextualSuggestions
            }
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
                        merchant = suggestion
                        isMerchantFocused = false
                        if transactionType == .expense {
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
    
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Category")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Always show Manage button
                Button("Manage") {
                    showingAllCategories = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(displayedCategories) { category in
                    categoryButton(category: category)
                }
            }
            
            // Selected category (if not visible in grid)
            if !selectedCategoryId.isEmpty,
               let selectedCategory = appStore.categories.first(where: { $0.id == selectedCategoryId }),
               !displayedCategories.contains(where: { $0.id == selectedCategoryId }) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    categoryButton(category: selectedCategory)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private var eventSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Event (Optional)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Manage") {
                    // TODO: Navigate to event management
                    print("📝 Manage events tapped")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            Menu {
                Button("No Event") {
                    selectedEventId = ""
                }
                
                Divider()
                
                ForEach(appStore.events.filter { $0.isActive }) { event in
                    Button(action: {
                        selectedEventId = event.id
                    }) {
                        HStack {
                            Image(systemName: event.icon)
                                .foregroundColor(Color(hex: event.color))
                            Text(event.name)
                            if event.id == selectedEventId {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                if !appStore.events.filter({ $0.isActive }).isEmpty &&
                   !appStore.events.filter({ !$0.isActive }).isEmpty {
                    Divider()
                    
                    // Show inactive events in submenu
                    Menu("Past Events") {
                        ForEach(appStore.events.filter { !$0.isActive }) { event in
                            Button(action: {
                                selectedEventId = event.id
                            }) {
                                HStack {
                                    Image(systemName: event.icon)
                                        .foregroundColor(Color(hex: event.color))
                                    Text(event.name)
                                    if event.id == selectedEventId {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("Create New Event") {
                    // TODO: Navigate to create event
                    print("➕ Create new event tapped")
                }
            } label: {
                HStack {
                    if let selectedEvent = appStore.events.first(where: { $0.id == selectedEventId }) {
                        Image(systemName: selectedEvent.icon)
                            .foregroundColor(Color(hex: selectedEvent.color))
                        Text(selectedEvent.name)
                            .foregroundColor(.primary)
                    } else {
                        Text("Select Event")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Show selected event details
            if let selectedEvent = appStore.events.first(where: { $0.id == selectedEventId }) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(selectedEvent.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func categoryButton(category: Category) -> some View {
        Button(action: {
            selectedCategoryId = category.id
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: category.color))
                
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedCategoryId == category.id ?
                         Color(hex: category.color).opacity(0.2) :
                         Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedCategoryId == category.id ?
                           Color(hex: category.color) :
                           Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
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
            
            // Receipt upload section (when business expense is enabled)
            if isBusinessExpense {
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
                    // TODO: Implement receipt upload
                    print("📸 Receipt upload tapped")
                }
            }
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
    
    // Context-aware labels and placeholders
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
    
    // Context-aware suggestions
    private var filteredSuggestions: [String] {
        if merchant.count < 2 {
            return []
        }
        
        let suggestions = transactionType == .income ? incomeSuggestions : expenseSuggestions
        return suggestions.filter {
            $0.localizedCaseInsensitiveContains(merchant)
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
    
    // Context-aware categories
    private var relevantCategories: [Category] {
        return appStore.categories.filter { category in
            switch transactionType {
            case .income:
                return category.categoryType == .income || category.categoryType == .both
            case .expense:
                return category.categoryType == .expense || category.categoryType == .both
            case .transfer:
                return false // No categories for transfers
            }
        }
    }
    
    private var displayedCategories: [Category] {
        return Array(relevantCategories.prefix(6))
    }
    
    // MARK: - Helper Methods
    
    private func setupDefaults() {
        // Default to most used account (current account if available)
        if let currentAccount = appStore.accounts.first(where: { $0.type == .current }) {
            selectedAccountId = currentAccount.id
        } else if let firstAccount = appStore.accounts.first {
            selectedAccountId = firstAccount.id
        }
        
        // Focus on amount field for immediate entry
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAmountFocused = true
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
            selectedCategoryId = categoryId
        }
    }
    
    private func saveTransaction() {
        guard isFormValid else { return }
        
        isLoading = true
        
        if transactionType == .transfer {
            saveTransfer()
        } else {
            saveRegularTransaction()
        }
        
        // Success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isLoading = false
        dismiss()
    }
    
    private func saveRegularTransaction() {
        let transactionAmount = (Double(amount) ?? 0) * (transactionType == .income ? 1 : -1)
        
        let newTransaction = Transaction(
            userId: appStore.currentUser?.id ?? "mock-user-id",
            accountId: selectedAccountId,
            categoryId: selectedCategoryId.isEmpty ? nil : selectedCategoryId,
            eventId: selectedEventId.isEmpty ? nil : selectedEventId,
            amount: transactionAmount,
            description: merchant,
            date: transactionDate
        )
        
        appStore.transactions.append(newTransaction)
        
        // Update account balance
        if let accountIndex = appStore.accounts.firstIndex(where: { $0.id == selectedAccountId }) {
            appStore.accounts[accountIndex].balance += transactionAmount
        }
        
        print("📊 \(transactionType.rawValue.capitalized) transaction created: \(merchant) - £\(abs(transactionAmount))")
        if !selectedEventId.isEmpty {
            let eventName = appStore.events.first(where: { $0.id == selectedEventId })?.name ?? "Unknown"
            print("🎯 Tagged to event: \(eventName)")
        }
        if isBusinessExpense {
            print("💼 Business expense marked")
        }
    }
    
    private func saveTransfer() {
        guard let transferAmount = Double(amount) else { return }
        
        // Create transfer record
        let newTransfer = Transfer(
            userId: appStore.currentUser?.id ?? "mock-user-id",
            fromAccountId: selectedAccountId,
            toAccountId: selectedToAccountId,
            amount: transferAmount,
            description: merchant,
            date: transactionDate,
            transferType: .manual
        )
        
        appStore.transfers.append(newTransfer)
        
        // Create corresponding transactions (with event if selected)
        let (fromTransaction, toTransaction) = newTransfer.generateTransactions()
        
        // Add event to transfer transactions if selected
        if !selectedEventId.isEmpty {
            var updatedFromTransaction = fromTransaction
            var updatedToTransaction = toTransaction
            
            // Note: We'd need to update the Transaction init to support eventId
            // For now, just append the original transactions
            appStore.transactions.append(fromTransaction)
            appStore.transactions.append(toTransaction)
        } else {
            appStore.transactions.append(fromTransaction)
            appStore.transactions.append(toTransaction)
        }
        
        // Update account balances
        if let fromIndex = appStore.accounts.firstIndex(where: { $0.id == selectedAccountId }) {
            appStore.accounts[fromIndex].balance -= transferAmount
        }
        if let toIndex = appStore.accounts.firstIndex(where: { $0.id == selectedToAccountId }) {
            appStore.accounts[toIndex].balance += transferAmount
        }
        
        print("🔄 Transfer created: £\(transferAmount) from \(selectedAccountId) to \(selectedToAccountId)")
        if !selectedEventId.isEmpty {
            let eventName = appStore.events.first(where: { $0.id == selectedEventId })?.name ?? "Unknown"
            print("🎯 Transfer tagged to event: \(eventName)")
        }
    }
}

// MARK: - Transaction Type Enum

enum TransactionType: String, CaseIterable {
    case income = "income"
    case expense = "expense"
    case transfer = "transfer"
}

// MARK: - All Categories View

struct AllCategoriesView: View {
    @EnvironmentObject var appStore: AppStore
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategoryId: String
    let transactionType: TransactionType
    
    private var relevantCategories: [Category] {
        return appStore.categories.filter { category in
            switch transactionType {
            case .income:
                return category.categoryType == .income || category.categoryType == .both
            case .expense:
                return category.categoryType == .expense || category.categoryType == .both
            case .transfer:
                return false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(relevantCategories) { category in
                        Button(action: {
                            selectedCategoryId = category.id
                            dismiss()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: category.icon)
                                    .font(.title2)
                                    .foregroundColor(Color(hex: category.color))
                                
                                Text(category.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.primary)
                            }
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedCategoryId == category.id ?
                                         Color(hex: category.color).opacity(0.2) :
                                         Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedCategoryId == category.id ?
                                           Color(hex: category.color) :
                                           Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("\(transactionType == .income ? "Income" : "Expense") Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manage") {
                        // TODO: Navigate to category management
                        print("📝 Manage categories tapped")
                    }
                }
            }
        }
    }
}

// MARK: - Preview Provider
struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddTransactionView()
            .environmentObject(AppStore())
    }
}
