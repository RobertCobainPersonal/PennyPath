//
//  CategorySelectionView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//


//
//  CategorySelectionView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import SwiftUI

struct CategorySelectionView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    
    // The binding to update the selected ID in the parent view
    @Binding var selectedCategoryId: String?
    
    private var topLevelCategories: [Category] {
        store.categories.filter { $0.parentCategoryId == nil }.sorted { $0.name < $1.name }
    }
    
    private func subCategories(for parent: Category) -> [Category] {
        store.categories.filter { $0.parentCategoryId == parent.id }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        List {
            ForEach(topLevelCategories) { category in
                Section(header: Text(category.name)) {
                    // Make the top-level category tappable
                    Button(action: {
                        selectedCategoryId = category.id
                        dismiss()
                    }) {
                        CategoryRowView(category: category)
                    }
                    .buttonStyle(.plain) // Use plain style to make it look like a list row
                    
                    ForEach(subCategories(for: category)) { subCategory in
                        // Make the sub-category tappable
                        Button(action: {
                            selectedCategoryId = subCategory.id
                            dismiss()
                        }) {
                            SubCategoryRowView(category: subCategory)
                                .padding(.leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Select Category")
    }
}