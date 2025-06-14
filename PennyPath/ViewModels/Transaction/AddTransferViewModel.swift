//
//  AddTransferViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//


//
//  AddTransferViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import Foundation
import FirebaseAuth

@MainActor
class AddTransferViewModel: ObservableObject {
    @Published var amountStr: String = ""
    @Published var fromAccountId: String = ""
    @Published var toAccountId: String = ""
    @Published var date: Date = Date()
    @Published var description: String = ""

    var isFormValid: Bool {
        !amountStr.isEmpty && !fromAccountId.isEmpty && !toAccountId.isEmpty && fromAccountId != toAccountId
    }

    func save(fromAccount: Account, toAccount: Account) async throws {
        guard let amount = Double(amountStr) else {
            throw NSError(domain: "AddTransferViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid amount."])
        }

        try await TransactionService.shared.addTransfer(
            fromAccount: fromAccount,
            toAccount: toAccount,
            amount: amount,
            date: date,
            description: description
        )
    }
}
