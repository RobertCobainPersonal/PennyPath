//
//  AddBudgetViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//


//
//  AddBudgetViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 14/06/2025.
//

import Foundation
import FirebaseFirestore

@MainActor
class AddBudgetViewModel: ObservableObject {
    
    @Published var amountStr: String = ""
    @Published var categoryId: String? = nil
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    
    var isFormValid: Bool {
        guard let amount = Double(amountStr), amount > 0 else { return false }
        return categoryId != nil
    }
    
    func save() async throws {
        guard let categoryId = categoryId, let amount = Double(amountStr) else {
            // This case should be prevented by the isFormValid check, but it's good practice.
            throw NSError(domain: "AddBudgetViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid form data."])
        }
        
        let newBudget = Budget(
            categoryId: categoryId,
            amount: amount,
            startDate: Timestamp(date: startDate),
            endDate: Timestamp(date: endDate)
        )
        
        try await BudgetService.shared.saveBudget(newBudget)
    }
}