//
//  TransactionDetailView.swift
//  PennyPath
//
//  Created by Robert Cobain on 18/06/2025.
//

import SwiftUI

struct TransactionDetailView: View {
    @EnvironmentObject var appStore: AppStore
    @Environment(\.dismiss) private var dismiss
    
    let transaction: Transaction
    @State private var showingEditTransaction = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Transaction header
                transactionHeaderSection
                
                // Transaction details
                transactionDetailsSection
                
                // Account information
                accountInformationSection
                
                // Category information (if categorized)
                if associatedCategory != nil {
                    categoryInformationSection
                }
                
                // Event information (if tagged)
                if associatedEvent != nil {
                    eventInformationSection
                }
                
                // Business expense information (if applicable)
                if isBusinessExpense {
                    businessExpenseSection
                }
                
                // Scheduled transaction information (if applicable)
                if transaction.isScheduled {
                    scheduledTransactionSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Transaction") {
                        showingEditTransaction = true
                    }
                    
                    Button("Duplicate Transaction") {
                        duplicateTransaction()
                    }
                    
                    Divider()
                    
                    Button("Delete Transaction", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingEditTransaction) {
            EditTransactionView(transaction: transaction)
        }
        .alert("Delete Transaction?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTransaction()
            }
        } message: {
            Text("This will permanently delete \"\(transaction.description)\" and cannot be undone.")
        }
    }
    
    // MARK: - View Sections
    
    private var transactionHeaderSection: some View {
        CardView {
            VStack(spacing: 16) {
                // Category icon and amount
                HStack {
                    categoryIcon
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(transaction.amount.formattedAsCurrency)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(amountColor)
                        
                        Text(transactionTypeText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Transaction description
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Text(transaction.description)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Date and status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(transaction.date.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    if transaction.isScheduled {
                        statusBadge
                    }
                }
            }
        }
    }
    
    private var transactionDetailsSection: some View {
        CardView {
            VStack(spacing: 16) {
                sectionHeader(title: "Transaction Details", icon: "info.circle")
                
                VStack(spacing: 12) {
                    detailRow(label: "Transaction ID", value: String(transaction.id.prefix(8)) + "...")
                    
                    detailRow(label: "Created", value: transaction.createdAt.formatted(date: .abbreviated, time: .shortened))
                    
                    if transaction.isScheduled {
                        detailRow(label: "Status", value: "Scheduled")
                        
                        if let recurrence = transaction.recurrence {
                            detailRow(label: "Recurrence", value: recurrence.displayName)
                        }
                    } else {
                        detailRow(label: "Status", value: "Completed")
                    }
                }
            }
        }
    }
    
    private var accountInformationSection: some View {
        CardView {
            VStack(spacing: 16) {
                sectionHeader(title: "Account", icon: "building.columns")
                
                if let account = associatedAccount {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: account.type.color).opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: account.type.icon)
                                .font(.headline)
                                .foregroundColor(Color(hex: account.type.color))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.name)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text(account.type.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Current Balance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(account.balance.formattedAsCurrency)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(account.balance >= 0 ? .green : .red)
                        }
                    }
                } else {
                    Text("Account not found")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
    }
    
    private var categoryInformationSection: some View {
        CardView {
            VStack(spacing: 16) {
                sectionHeader(title: "Category", icon: "tag")
                
                if let category = associatedCategory {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: category.color).opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: category.icon)
                                .font(.headline)
                                .foregroundColor(Color(hex: category.color))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text(category.categoryType.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var eventInformationSection: some View {
        CardView {
            VStack(spacing: 16) {
                sectionHeader(title: "Event", icon: "calendar")
                
                if let event = associatedEvent {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: event.color).opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: event.icon)
                                    .font(.headline)
                                    .foregroundColor(Color(hex: event.color))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.name)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                if !event.description.isEmpty {
                                    Text(event.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        if let startDate = event.startDate, let endDate = event.endDate {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Event Period")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var businessExpenseSection: some View {
        CardView {
            VStack(spacing: 16) {
                sectionHeader(title: "Business Expense", icon: "briefcase")
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("This transaction is marked as a business expense")
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Receipt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Not attached")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    private var scheduledTransactionSection: some View {
        CardView {
            VStack(spacing: 16) {
                sectionHeader(title: "Scheduled Payment", icon: "calendar.badge.clock")
                
                VStack(spacing: 12) {
                    if let recurrence = transaction.recurrence {
                        detailRow(label: "Frequency", value: recurrence.displayName)
                        
                        let nextDate = recurrence.nextDate(from: transaction.date)
                        detailRow(label: "Next Payment", value: nextDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    
                    HStack {
                        Text("This payment will be automatically processed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 60, height: 60)
            
            Image(systemName: iconName)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(iconForegroundColor)
        }
    }
    
    private var statusBadge: some View {
        Text("Scheduled")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.15))
            )
    }
    
    // MARK: - Computed Properties
    
    private var associatedAccount: Account? {
        appStore.accounts.first { $0.id == transaction.accountId }
    }
    
    private var associatedCategory: Category? {
        guard let categoryId = transaction.categoryId else { return nil }
        return appStore.categories.first { $0.id == categoryId }
    }
    
    private var associatedEvent: Event? {
        guard let eventId = transaction.eventId else { return nil }
        return appStore.events.first { $0.id == eventId }
    }
    
    private var amountColor: Color {
        transaction.amount >= 0 ? .green : .primary
    }
    
    private var transactionTypeText: String {
        if transaction.categoryId == nil {
            return "Transfer"
        }
        return transaction.amount >= 0 ? "Income" : "Expense"
    }
    
    private var isBusinessExpense: Bool {
        // TODO: Add business expense flag to Transaction model
        // For now, we'll assume based on certain categories or description
        return transaction.description.lowercased().contains("business") ||
               transaction.description.lowercased().contains("work")
    }
    
    private var iconName: String {
        if let category = associatedCategory {
            return category.icon
        }
        
        if transaction.categoryId == nil {
            return "arrow.left.arrow.right" // Transfer
        }
        
        return transaction.amount >= 0 ? "arrow.down" : "arrow.up"
    }
    
    private var iconBackgroundColor: Color {
        if let category = associatedCategory {
            return Color(hex: category.color).opacity(0.15)
        }
        
        return transaction.amount >= 0 ? Color.green.opacity(0.15) : Color.blue.opacity(0.15)
    }
    
    private var iconForegroundColor: Color {
        if let category = associatedCategory {
            return Color(hex: category.color)
        }
        
        return transaction.amount >= 0 ? .green : .blue
    }
    
    // MARK: - Actions
    
    private func duplicateTransaction() {
        // Create a new transaction with the same details but today's date
        let duplicatedTransaction = Transaction(
            userId: transaction.userId,
            accountId: transaction.accountId,
            categoryId: transaction.categoryId,
            bnplPlanId: transaction.bnplPlanId,
            eventId: transaction.eventId,
            amount: transaction.amount,
            description: transaction.description,
            date: Date(), // Today's date
            isScheduled: false, // Duplicated transactions are not scheduled
            recurrence: nil
        )
        
        appStore.transactions.append(duplicatedTransaction)
        
        // Update account balance
        if let accountIndex = appStore.accounts.firstIndex(where: { $0.id == transaction.accountId }) {
            appStore.accounts[accountIndex].balance += transaction.amount
        }
        
        // Success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("💫 Transaction duplicated: \(transaction.description)")
    }
    
    private func deleteTransaction() {
        // Remove transaction from the array
        appStore.transactions.removeAll { $0.id == transaction.id }
        
        // Reverse the account balance change
        if let accountIndex = appStore.accounts.firstIndex(where: { $0.id == transaction.accountId }) {
            appStore.accounts[accountIndex].balance -= transaction.amount
        }
        
        // Success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("🗑️ Transaction deleted: \(transaction.description)")
        dismiss()
    }
}

// MARK: - Preview Provider
struct TransactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TransactionDetailView(
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
}
