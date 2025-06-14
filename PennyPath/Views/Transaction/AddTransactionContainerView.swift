//
//  AddTransactionContainerView.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import SwiftUI

struct AddTransactionContainerView: View {
    @Environment(\.dismiss) private var dismiss
    
    // An enum to define the available transaction types
    private enum TransactionType: String, CaseIterable, Identifiable {
        case expense = "Expense"
        case income = "Income"
        case transfer = "Transfer"
        var id: Self { self }
    }
    
    @State private var selectedType: TransactionType = .expense

    var body: some View {
        // NOTE: The NavigationView from this view was moved into the child views
        // (AddExpenseView, etc.) so they can be presented correctly in sheets.
        VStack {
            Picker("Transaction Type", selection: $selectedType) {
                ForEach(TransactionType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Switch between the different forms based on the picker selection
            switch selectedType {
            case .expense:
                // We now pass a new, empty ViewModel to the view.
                AddExpenseView(
                    viewModel: AddExpenseViewModel(),
                    onSave: { dismiss() }
                )
            case .income:
                // We do the same for the income view.
                AddIncomeView(
                    viewModel: AddIncomeViewModel(),
                    onSave: { dismiss() }
                )
            case .transfer:
                // AddTransferView does not require a ViewModel in its init yet.
                AddTransferView(onSave: { dismiss() })
            }
            
            Spacer()
        }
    }
}

// The Preview now also needs to be updated to reflect these changes
struct AddTransactionContainerView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStore = AppStore()
        
        let sampleAccount1 = Account(id: "acc1", name: "Current Account", type: .currentAccount, institution: "Monzo", anchorBalance: 1500, anchorDate: .init(date: Date()))
        let sampleAccount2 = Account(id: "acc2", name: "Savings", type: .savings, institution: "HSBC", anchorBalance: 5000, anchorDate: .init(date: Date()))
        let sampleAccount3 = Account(id: "acc3", name: "Klarna", type: .bnpl, institution: "Klarna", anchorBalance: -150, anchorDate: .init(date: Date()))
        
        let samplePlan = BNPLPlan(id: "plan1", provider: "Klarna", planName: "Pay in 3", feeType: .none, installments: 3, paymentFrequency: .monthly)
        
        mockStore.accounts = [sampleAccount1, sampleAccount2, sampleAccount3]
        mockStore.bnplPlans = [samplePlan]
        mockStore.calculatedBalances["acc1"] = 1500
        mockStore.calculatedBalances["acc2"] = 5000
        mockStore.calculatedBalances["acc3"] = -150
        
        return AddTransactionContainerView()
            .environmentObject(mockStore)
    }
}
