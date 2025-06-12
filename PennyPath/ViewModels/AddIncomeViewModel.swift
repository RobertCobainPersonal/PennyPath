//
//  AddIncomeViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//


//
//  AddIncomeViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AddIncomeViewModel: ObservableObject {
    @Published var amountStr: String = ""
    @Published var selectedAccountId: String = ""
    @Published var date: Date = Date()
    @Published var description: String = ""

    var isFormValid: Bool {
        !amountStr.isEmpty && !selectedAccountId.isEmpty
    }

    func save() async throws {
        guard let userId = Auth.auth().currentUser?.uid, let amount = Double(amountStr) else {
            throw NSError(domain: "AddIncomeViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid data."])
        }

        let details = TransactionDetails(
            amount: amount,
            accountId: selectedAccountId,
            date: date,
            description: description,
            category: "Income", // Category is fixed for income
            isBNPL: false,
            bnplPlan: nil,
            bnplFundingAccountId: nil,
            bnplSchedule: nil
        )

        try await TransactionService.shared.addTransaction(details: details, for: userId)
    }
}