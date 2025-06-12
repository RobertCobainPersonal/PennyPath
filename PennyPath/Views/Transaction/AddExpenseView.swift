//
//  AddExpenseView.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//


//
//  AddExpenseView.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import SwiftUI

struct AddExpenseView: View {
    @StateObject private var viewModel = AddExpenseViewModel()
    @EnvironmentObject var store: AppStore
    
    // We pass this in from the parent view to tell it to close the sheet.
    var onSave: () -> Void

    private var selectedPlan: BNPLPlan? {
        store.bnplPlans.first { $0.id == viewModel.selectedPlanId }
    }
    
    private var schedulePreview: BNPLSchedulePreview? {
        guard let plan = selectedPlan, let amount = Double(viewModel.amountStr) else { return nil }
        
        // This is a simplified preview calculation for demonstration.
        // A more robust implementation would move this logic into the ViewModel.
        let fee = 0.0 // Simplified
        let totalDebt = amount + fee
        let remaining = totalDebt / Double(plan.installments)
        
        return .init(initialPayment: 0, fee: fee, installmentAmount: remaining, remainingBalance: totalDebt, schedule: [])
    }
    
    var body: some View {
        Form {
            Section(header: Text("Expense Details")) {
                TextField("Amount", text: $viewModel.amountStr)
                    .keyboardType(.decimalPad)
                DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                TextField("Description", text: $viewModel.description)
                TextField("Category", text: $viewModel.category)
            }
            
            Section(header: Text("Account")) {
                Picker("Account", selection: $viewModel.selectedAccountId) {
                    ForEach(store.accounts) { account in
                        Text(account.name).tag(account.id ?? "")
                    }
                }
            }
            
            Section(header: Text("Flags")) {
                Toggle("BNPL Purchase", isOn: $viewModel.isBNPL.animation())
                if viewModel.isBNPL {
                    Picker("BNPL Plan", selection: $viewModel.selectedPlanId) {
                        ForEach(store.bnplPlans) { plan in
                            Text(plan.planName).tag(plan.id ?? "")
                        }
                    }
                    Picker("Funding Account", selection: $viewModel.selectedFundingAccountId) {
                         ForEach(store.accounts.filter { $0.type == .currentAccount }) { account in
                            Text(account.name).tag(account.id ?? "")
                        }
                    }
                }
            }
            
            Section {
                Button("Save Expense") {
                    Task {
                        do {
                            try await viewModel.save(plan: selectedPlan, schedule: schedulePreview)
                            onSave() // Close the sheet on success
                        } catch {
                            // Handle error, e.g., show an alert
                            print("Error saving expense: \(error.localizedDescription)")
                        }
                    }
                }
                .disabled(!viewModel.isFormValid)
            }
        }
        .onAppear {
            // Set default selections
            if viewModel.selectedAccountId.isEmpty, let account = store.accounts.first {
                viewModel.selectedAccountId = account.id ?? ""
            }
            if viewModel.selectedPlanId.isEmpty, let plan = store.bnplPlans.first {
                viewModel.selectedPlanId = plan.id ?? ""
            }
            if viewModel.selectedFundingAccountId.isEmpty, let fundingAccount = store.accounts.first(where: { $0.type == .currentAccount }) {
                viewModel.selectedFundingAccountId = fundingAccount.id ?? ""
            }
        }
    }
}