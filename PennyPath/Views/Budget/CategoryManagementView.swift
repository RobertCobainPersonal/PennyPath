//
//  CategoryManagementView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import SwiftUI

struct CategoryManagementView: View {
    
    // 1. The view now uses the new ViewModel
    @StateObject private var viewModel = CategoryManagementViewModel()
    @EnvironmentObject var store: AppStore
    
    @State private var showingAddCategorySheet = false
    
    // 2. These computed properties now read from the ViewModel's categories
    private var topLevelCategories: [Category] {
        viewModel.categories.filter { $0.parentCategoryId == nil }.sorted { $0.name < $1.name }
    }
    
    private func subCategories(for parent: Category) -> [Category] {
        viewModel.categories.filter { $0.parentCategoryId == parent.id }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        // The main list structure
        List {
            ForEach(topLevelCategories) { category in
                Section(header: Text(category.name)) {
                    // Row for the parent category
                    CategoryRowView(category: category)
                        // Delete action for the parent category
                        .swipeActions {
                            Button(role: .destructive) {
                                if let categoryId = category.id {
                                    viewModel.deleteCategory(withId: categoryId)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    
                    // List the sub-categories for this parent
                    let children = subCategories(for: category)
                    ForEach(children) { subCategory in
                        SubCategoryRowView(category: subCategory)
                            .padding(.leading)
                    }
                    // 3. The .onDelete modifier for sub-categories
                    .onDelete { offsets in
                        // This gets the IDs of the sub-categories to delete
                        let idsToDelete = offsets.compactMap { children[$0].id }
                        for id in idsToDelete {
                            viewModel.deleteCategory(withId: id)
                        }
                    }
                }
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
        // 4. Connect the ViewModel to the AppStore when the view appears
        .onAppear {
            viewModel.listenForData(store: store)
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
