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
    var onSave: () -> Void

    // --- NEW: Computed property to find the selected category object ---
    private var selectedCategory: Category? {
        store.categories.first { $0.id == viewModel.categoryId }
    }

    private var selectedPlan: BNPLPlan? {
        store.bnplPlans.first { $0.id == viewModel.selectedPlanId }
    }
    
    // --- UPDATED: This now calls the ViewModel's logic ---
    private var schedulePreview: BNPLSchedulePreview? {
        guard let plan = selectedPlan else { return nil }
        return viewModel.calculateSchedulePreview(for: plan)
    }
    
    var body: some View {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Amount", text: $viewModel.amountStr)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    TextField("Description", text: $viewModel.description)
                    
                    // --- UPDATED: Replaced TextField with a NavigationLink ---
                    NavigationLink {
                        // Destination is our new selection view
                        CategorySelectionView(selectedCategoryId: $viewModel.categoryId)
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            if let category = selectedCategory {
                                // Display the selected category's name
                                Text(category.name)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            
            Section(header: Text("Account")) {
                Picker("Charge to Account", selection: $viewModel.selectedAccountId) {
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
                            onSave()
                        } catch {
                            print("Error saving expense: \(error.localizedDescription)")
                        }
                    }
                }
                .disabled(!viewModel.isFormValid)
            }
        }
        .onAppear {
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
