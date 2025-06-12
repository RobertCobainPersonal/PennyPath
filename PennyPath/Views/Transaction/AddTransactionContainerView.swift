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
        NavigationView {
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
                    AddExpenseView(onSave: { dismiss() })
                case .income:
                    AddIncomeView(onSave: { dismiss() })
                case .transfer:
                    AddTransferView(onSave: { dismiss() })
                }
                
                Spacer()
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// As requested, here is a detailed PreviewProvider with mock data.
struct AddTransactionContainerView_Previews: PreviewProvider {
    static var previews: some View {
        // 1. Create a mock AppStore for the preview.
        let mockStore = AppStore()
        
        // 2. Create sample accounts.
        let sampleAccount1 = Account(id: "acc1", name: "Current Account", type: .currentAccount, institution: "Monzo", currentBalance: 1500)
        let sampleAccount2 = Account(id: "acc2", name: "Savings", type: .savings, institution: "HSBC", currentBalance: 5000)
        let sampleAccount3 = Account(id: "acc3", name: "Klarna", type: .bnpl, institution: "Klarna", currentBalance: -150)
        
        // 3. Create a sample BNPL plan.
        let samplePlan = BNPLPlan(id: "plan1", provider: "Klarna", planName: "Pay in 3", feeType: .none, installments: 3, paymentFrequency: .monthly)
        
        // 4. Populate the mock store.
        mockStore.accounts = [sampleAccount1, sampleAccount2, sampleAccount3]
        mockStore.bnplPlans = [samplePlan]
        
        // 5. Return the view and inject the populated store.
        return AddTransactionContainerView()
            .environmentObject(mockStore)
    }
}
