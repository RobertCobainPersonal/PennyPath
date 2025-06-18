//
//  TransactionFiltersSheet.swift
//  PennyPath
//
//  Created by Robert Cobain on 17/06/2025.
//

import SwiftUI

struct TransactionFiltersSheet: View {
    @EnvironmentObject var appStore: AppStore
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedAccount: String
    @Binding var selectedCategory: String
    @Binding var selectedEvent: String
    @Binding var selectedType: TransactionTypeFilter
    @Binding var selectedDateRange: DateRangeFilter
    
    let onReset: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                // Account Filter Section
                Section("Account") {
                    AccountPicker(
                        selectedAccountId: $selectedAccount,
                        placeholder: "All Accounts",
                        showBalance: true,
                        isRequired: false
                    )
                }
                
                // Category Filter Section
                Section("Category") {
                    CategoryFilterPicker(
                        selectedCategoryId: $selectedCategory,
                        transactionType: selectedType == .income ? .income : .expense
                    )
                }
                
                // Event Filter Section
                Section("Event") {
                    EventPicker(
                        selectedEventId: $selectedEvent,
                        isRequired: false,
                        showCreateNew: false,
                        placeholder: "All Events"
                    )
                }
                
                // Transaction Type Section
                Section("Transaction Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(TransactionTypeFilter.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Date Range Section
                Section("Date Range") {
                    Picker("Period", selection: $selectedDateRange) {
                        ForEach(DateRangeFilter.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Show date range preview
                    HStack {
                        Text("From:")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(selectedDateRange.dateRange.lowerBound.formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(.primary)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("To:")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(selectedDateRange.dateRange.upperBound.formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(.primary)
                    }
                    .font(.caption)
                }
                
                // Filter Summary Section
                if hasActiveFilters {
                    Section("Active Filters") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(activeFilterDescriptions, id: \.self) { description in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text(description)
                                        .font(.subheadline)
                                }
                            }
                            
                            Button("Clear All Filters") {
                                onReset()
                            }
                            .foregroundColor(.red)
                            .padding(.top, 8)
                        }
                    }
                }
                
                // Quick Filter Presets Section
                Section("Quick Filters") {
                    VStack(spacing: 12) {
                        quickFilterButton(
                            title: "This Week's Spending",
                            subtitle: "Expenses from the last 7 days",
                            icon: "calendar.badge.minus"
                        ) {
                            selectedType = .expense
                            selectedDateRange = .thisWeek
                            selectedAccount = ""
                            selectedCategory = ""
                            selectedEvent = ""
                        }
                        
                        quickFilterButton(
                            title: "Income This Month",
                            subtitle: "All income sources this month",
                            icon: "arrow.up.circle"
                        ) {
                            selectedType = .income
                            selectedDateRange = .thisMonth
                            selectedAccount = ""
                            selectedCategory = ""
                            selectedEvent = ""
                        }
                        
                        quickFilterButton(
                            title: "Event Transactions",
                            subtitle: "Transactions tagged to events",
                            icon: "tag.circle"
                        ) {
                            selectedType = .all
                            selectedDateRange = .last3Months
                            selectedAccount = ""
                            selectedCategory = ""
                            // Don't clear event filter - let user choose which event
                        }
                    }
                }
            }
            .navigationTitle("Filter Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        onReset()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func quickFilterButton(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Computed Properties
    
    private var hasActiveFilters: Bool {
        !selectedAccount.isEmpty ||
        !selectedCategory.isEmpty ||
        !selectedEvent.isEmpty ||
        selectedType != .all ||
        selectedDateRange != .thisMonth
    }
    
    private var activeFilterDescriptions: [String] {
        var descriptions: [String] = []
        
        if !selectedAccount.isEmpty,
           let account = appStore.accounts.first(where: { $0.id == selectedAccount }) {
            descriptions.append("Account: \(account.name)")
        }
        
        if !selectedCategory.isEmpty,
           let category = appStore.categories.first(where: { $0.id == selectedCategory }) {
            descriptions.append("Category: \(category.name)")
        }
        
        if !selectedEvent.isEmpty,
           let event = appStore.events.first(where: { $0.id == selectedEvent }) {
            descriptions.append("Event: \(event.name)")
        }
        
        if selectedType != .all {
            descriptions.append("Type: \(selectedType.displayName)")
        }
        
        if selectedDateRange != .thisMonth {
            descriptions.append("Period: \(selectedDateRange.displayName)")
        }
        
        return descriptions
    }
}

// MARK: - Category Filter Picker Component

struct CategoryFilterPicker: View {
    @EnvironmentObject var appStore: AppStore
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
                return false // No categories for transfers
            }
        }
    }
    
    var body: some View {
        Menu {
            Button("All Categories") {
                selectedCategoryId = ""
            }
            
            if !relevantCategories.isEmpty {
                Divider()
                
                ForEach(relevantCategories) { category in
                    Button(action: {
                        selectedCategoryId = category.id
                    }) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(hex: category.color))
                            
                            Text(category.name)
                            
                            if category.id == selectedCategoryId {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        } label: {
            HStack {
                if let selectedCategory = relevantCategories.first(where: { $0.id == selectedCategoryId }) {
                    Image(systemName: selectedCategory.icon)
                        .foregroundColor(Color(hex: selectedCategory.color))
                    
                    Text(selectedCategory.name)
                        .foregroundColor(.primary)
                } else {
                    Text("All Categories")
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
}

// MARK: - Preview Provider
struct TransactionFiltersSheet_Previews: PreviewProvider {
    static var previews: some View {
        TransactionFiltersSheet(
            selectedAccount: .constant(""),
            selectedCategory: .constant(""),
            selectedEvent: .constant(""),
            selectedType: .constant(.all),
            selectedDateRange: .constant(.thisMonth),
            onReset: {}
        )
        .environmentObject(AppStore())
    }
}
