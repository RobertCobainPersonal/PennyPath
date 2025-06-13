//
//  AddCategoryView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import SwiftUI

struct AddCategoryView: View {
    @StateObject private var viewModel = AddCategoryViewModel()
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    
    // 1. UPDATED: Ensure we only list parent categories that have a valid ID.
    private var parentCategories: [Category] {
        store.categories.filter { $0.parentCategoryId == nil && $0.id != nil }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Name", text: $viewModel.name)
                    ColorPicker("Color", selection: $viewModel.color, supportsOpacity: false)
                    
                    NavigationLink {
                        IconPickerView(selectedIconName: $viewModel.iconName)
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            Image(systemName: viewModel.iconName)
                                .foregroundColor(viewModel.color)
                        }
                    }
                }
                
                Section(header: Text("Sub-category (Optional)")) {
                    Picker("Parent Category", selection: Binding(
                        get: { viewModel.parentCategoryId ?? "none" },
                        set: { viewModel.parentCategoryId = ($0 == "none" ? nil : $0) }
                    )) {
                        Text("None (Top-level Category)").tag("none")
                        ForEach(parentCategories) { category in
                            // 2. CORRECTED: Use .id! to provide a non-optional String tag.
                            Text(category.name).tag(category.id!)
                        }
                    }
                }
                
                Section {
                    Button("Save Category") {
                        Task {
                            do {
                                try await viewModel.save()
                                dismiss()
                            } catch {
                                print("Error saving category: \(error.localizedDescription)")
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
            .navigationTitle("New Category")
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

struct AddCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStore = AppStore()
        mockStore.categories = [
            .init(id: "1", name: "Transport", iconName: "car.fill", colorHex: "#FF0000"),
            .init(id: "2", name: "Food", iconName: "fork.knife", colorHex: "#00FF00")
        ]
        
        return AddCategoryView()
            .environmentObject(mockStore)
    }
}
