//
//  CategorySelectionView.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

/// Reusable component for category selection in forms
/// Used in AddTransaction, EditTransaction, Budget creation, and category management
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
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
                    .fill(isSelected ?
                         Color(hex: category.color).opacity(0.2) :
                         Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ?
                           Color(hex: category.color) :
                           Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Grid-based category selection component
struct CategorySelectionGrid: View {
    let categories: [Category]
    @Binding var selectedCategoryId: String
    let columns: Int
    let maxDisplayed: Int?
    
    init(categories: [Category], selectedCategoryId: Binding<String>, columns: Int = 3, maxDisplayed: Int? = nil) {
        self.categories = categories
        self._selectedCategoryId = selectedCategoryId
        self.columns = columns
        self.maxDisplayed = maxDisplayed
    }
    
    private var displayedCategories: [Category] {
        if let max = maxDisplayed {
            return Array(categories.prefix(max))
        }
        return categories
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 12) {
            ForEach(displayedCategories) { category in
                CategoryButton(
                    category: category,
                    isSelected: selectedCategoryId == category.id
                ) {
                    selectedCategoryId = category.id
                }
            }
        }
    }
}

/// Complete category selection component with header and "See All" functionality
struct CategorySelectionView: View {
    @EnvironmentObject var appStore: AppStore
    @Binding var selectedCategoryId: String
    let transactionType: TransactionType
    let maxDisplayed: Int
    @State private var showingAllCategories = false
    
    init(selectedCategoryId: Binding<String>, transactionType: TransactionType, maxDisplayed: Int = 6) {
        self._selectedCategoryId = selectedCategoryId
        self.transactionType = transactionType
        self.maxDisplayed = maxDisplayed
    }
    
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
        return Array(relevantCategories.prefix(maxDisplayed))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with manage button
            HStack {
                Text("Category")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("See All") {
                    showingAllCategories = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // Category grid
            CategorySelectionGrid(
                categories: displayedCategories,
                selectedCategoryId: $selectedCategoryId,
                maxDisplayed: maxDisplayed
            )
            
            // Selected category (if not visible in grid)
            selectedCategoryDisplay
        }
        .sheet(isPresented: $showingAllCategories) {
            AllCategoriesView(
                selectedCategoryId: $selectedCategoryId,
                transactionType: transactionType
            )
        }
    }
    
    @ViewBuilder
    private var selectedCategoryDisplay: some View {
        if !selectedCategoryId.isEmpty,
           let selectedCategory = appStore.categories.first(where: { $0.id == selectedCategoryId }),
           !displayedCategories.contains(where: { $0.id == selectedCategoryId }) {
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected Category")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                CategoryButton(
                    category: selectedCategory,
                    isSelected: true
                ) {
                    // Allow deselection
                    selectedCategoryId = ""
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Full-screen category selection view
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
                CategorySelectionGrid(
                    categories: relevantCategories,
                    selectedCategoryId: $selectedCategoryId
                )
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
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Transaction Type Support
enum TransactionType: String, CaseIterable {
    case income = "income"
    case expense = "expense"
    case transfer = "transfer"
}

// MARK: - Preview Provider
struct CategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppStore = AppStore()
        
        VStack(spacing: 20) {
            // Expense category selection
            CategorySelectionView(
                selectedCategoryId: .constant("cat-food"),
                transactionType: .expense
            )
            
            Divider()
            
            // Income category selection
            CategorySelectionView(
                selectedCategoryId: .constant("cat-salary"),
                transactionType: .income
            )
            
            Divider()
            
            // Individual category button
            Text("Individual Category Button:")
                .font(.headline)
            
            HStack {
                CategoryButton(
                    category: Category(
                        userId: "test",
                        name: "Food & Dining",
                        color: "#FF6B6B",
                        icon: "fork.knife"
                    ),
                    isSelected: false
                ) {
                    print("Food category tapped")
                }
                
                CategoryButton(
                    category: Category(
                        userId: "test",
                        name: "Transport",
                        color: "#4ECDC4",
                        icon: "car.fill"
                    ),
                    isSelected: true
                ) {
                    print("Transport category tapped")
                }
                
                CategoryButton(
                    category: Category(
                        userId: "test",
                        name: "Entertainment",
                        color: "#45B7D1",
                        icon: "tv"
                    ),
                    isSelected: false
                ) {
                    print("Entertainment category tapped")
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .environmentObject(mockAppStore)
    }
}
