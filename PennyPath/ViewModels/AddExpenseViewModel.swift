//
//  AddExpenseViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//


//
//  AddExpenseViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AddExpenseViewModel: ObservableObject {
    @Published var amountStr: String = ""
    @Published var selectedAccountId: String = ""
    @Published var date: Date = Date()
    @Published var category: String = "Shopping"
    @Published var description: String = ""
    @Published var isBNPL: Bool = false
    @Published var selectedPlanId: String = ""
    @Published var selectedFundingAccountId: String = ""

    var isFormValid: Bool {
        !(amountStr.isEmpty || selectedAccountId.isEmpty) &&
        (isBNPL ? !(selectedPlanId.isEmpty || selectedFundingAccountId.isEmpty) : true)
    }

    func save(plan: BNPLPlan?, schedule: BNPLSchedulePreview?) async throws {
        guard let userId = Auth.auth().currentUser?.uid, let amount = Double(amountStr) else {
            throw NSError(domain: "AddExpenseViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid data."])
        }

        let details = TransactionDetails(
            amount: amount,
            accountId: selectedAccountId,
            date: date,
            description: description,
            category: category,
            isBNPL: isBNPL,
            bnplPlan: plan,
            bnplFundingAccountId: selectedFundingAccountId,
            bnplSchedule: schedule
        )

        try await TransactionService.shared.addTransaction(details: details, for: userId)
    }
}