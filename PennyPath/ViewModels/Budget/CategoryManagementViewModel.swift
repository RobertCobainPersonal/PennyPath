//
//  CategoryManagementViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//


//
//  CategoryManagementViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import Foundation
import Combine

@MainActor
class CategoryManagementViewModel: ObservableObject {
    
    @Published var categories = [Category]()
    private var cancellables = Set<AnyCancellable>()
    
    /// Subscribes to the `categories` publisher from the AppStore.
    /// - Parameter store: The central AppStore instance.
    func listenForData(store: AppStore) {
        store.$categories
            .assign(to: \.categories, on: self)
            .store(in: &cancellables)
    }
    
    /// Deletes a category at a specific set of offsets from the list.
    /// This method calls the CategoryService to handle the complex deletion logic.
    /// - Parameter offsets: The IndexSet provided by the onDelete modifier.
    func deleteCategory(at offsets: IndexSet) {
        // We need to determine which categories to delete from our local, sorted array.
        // This is more complex because the list is sectioned. We'll implement this
        // logic in the next step when we update the View.
        
        // For now, this is a placeholder to show the structure.
        print("Delete action triggered for offsets: \(offsets)")
    }
    
    /// Deletes a specific category by its ID.
    /// - Parameter categoryId: The ID of the category to be deleted.
    func deleteCategory(withId categoryId: String) {
        Task {
            do {
                try await CategoryService.shared.deleteCategory(withId: categoryId)
                print("Successfully deleted category \(categoryId) and its dependencies.")
            } catch {
                print("Error deleting category: \(error.localizedDescription)")
            }
        }
    }
}