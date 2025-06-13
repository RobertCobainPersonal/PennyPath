//
//  CategoryManagementView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import SwiftUI

struct CategoryManagementView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAddCategorySheet = false
    
    // Computed property to get only top-level categories
    private var topLevelCategories: [Category] {
        store.categories.filter { $0.parentCategoryId == nil }.sorted { $0.name < $1.name }
    }
    
    // A helper function to get the children of a specific category
    private func subCategories(for parent: Category) -> [Category] {
        store.categories.filter { $0.parentCategoryId == parent.id }.sorted { $0.name < $1.name }
    }
    
    // --- The Main Body is now much simpler ---
    var body: some View {
        List {
            ForEach(topLevelCategories) { category in
                // Call the helper function to build the section
                section(for: category)
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddCategorySheet.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCategorySheet) {
            AddCategoryView()
        }
    }
    
    // --- NEW: Helper function to build the complex section view ---
    private func section(for category: Category) -> some View {
        Section(header: Text(category.name)) {
            CategoryRowView(category: category)
            
            // List the sub-categories for this parent
            ForEach(subCategories(for: category)) { subCategory in
                SubCategoryRowView(category: subCategory)
                    .padding(.leading)
            }
        }
    }
}


// A slightly different row view for sub-categories to show indentation
struct SubCategoryRowView: View {
    let category: Category
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.turn.down.right")
                .foregroundColor(.secondary)
            
            Image(systemName: category.iconName)
                .foregroundColor(category.color)

            Text(category.name)
        }
    }
}

struct CategoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStore = AppStore()
        mockStore.categories = [
            .init(id: "1", name: "Transport", iconName: "car.fill", colorHex: "#FF5733"),
            .init(id: "2", name: "Food & Drink", iconName: "fork.knife", colorHex: "#33FF57"),
            .init(id: "3", name: "Groceries", iconName: "cart.fill", colorHex: "#3357FF", parentCategoryId: "2"),
            .init(id: "4", name: "Restaurants", iconName: "cup.and.saucer.fill", colorHex: "#FF33A1", parentCategoryId: "2")
        ]
        
        return NavigationView {
            CategoryManagementView()
                .environmentObject(mockStore)
        }
    }
}
