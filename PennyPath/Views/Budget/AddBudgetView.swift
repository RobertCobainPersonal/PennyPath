//
//  AddBudgetView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//


//
//  AddBudgetView.swift
//  PennyPath
//
//  Created by Robert Cobain on 14/06/2025.
//

import SwiftUI

struct AddBudgetView: View {
    @StateObject private var viewModel = AddBudgetViewModel()
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    // A computed property to find the full Category object from the selected ID
    private var selectedCategory: Category? {
        store.categories.first { $0.id == viewModel.categoryId }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Budget Details")) {
                    // Use the CategorySelectionView we already built
                    NavigationLink {
                        CategorySelectionView(selectedCategoryId: $viewModel.categoryId)
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            if let category = selectedCategory {
                                Text(category.name)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Text("£") // Or use a dynamic currency symbol
                        TextField("Amount", text: $viewModel.amountStr)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("Budget Period")) {
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                }
                
                Section {
                    Button("Save Budget") {
                        Task {
                            do {
                                try await viewModel.save()
                                dismiss() // Close the sheet on success
                            } catch {
                                // In a real app, show an alert to the user
                                print("Error saving budget: \(error.localizedDescription)")
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
            .navigationTitle("New Budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}


struct AddBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        // 1. Create a mock AppStore for the preview.
        let mockStore = AppStore()
        
        // 2. Create sample categories to choose from.
        let sampleCategory1 = Category(name: "Groceries", iconName: "cart.fill", colorHex: "#33FF57")
        let sampleCategory2 = Category(name: "Transport", iconName: "car.fill", colorHex: "#FF5733")
        
        // 3. Populate the mock store.
        mockStore.categories = [sampleCategory1, sampleCategory2]
        
        // 4. Return the view and inject the populated store.
        return AddBudgetView()
            .environmentObject(mockStore)
    }
}