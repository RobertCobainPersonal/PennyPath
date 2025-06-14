//
//  AddExpenseView.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import SwiftUI

struct AddExpenseView: View {
    // ViewModel is now passed in
    @StateObject private var viewModel: AddExpenseViewModel
    @EnvironmentObject var store: AppStore
    var onSave: () -> Void

    // New initializer
    init(viewModel: AddExpenseViewModel, onSave: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
    }

    private var selectedCategory: Category? {
        store.categories.first { $0.id == viewModel.categoryId }
    }

    private var selectedPlan: BNPLPlan? {
        store.bnplPlans.first { $0.id == viewModel.selectedPlanId }
    }
    
    private var schedulePreview: BNPLSchedulePreview? {
        guard let plan = selectedPlan else { return nil }
        return viewModel.calculateSchedulePreview(for: plan)
    }
    
    var body: some View {
        // We wrap the form in a NavigationView so it gets a title bar in the sheet
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Amount", text: $viewModel.amountStr)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    TextField("Description", text: $viewModel.description)
                    
                    NavigationLink {
                        CategorySelectionView(selectedCategoryId: $viewModel.categoryId)
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            if let category = selectedCategory {
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
            
                // We disable changing the BNPL status when editing
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
                .disabled(viewModel.isEditing)
            
                Section {
                    Button(viewModel.saveButtonText) {
                        Task {
                            do {
                                try await viewModel.saveOrUpdate(plan: selectedPlan, schedule: schedulePreview)
                                onSave()
                            } catch {
                                print("Error saving expense: \(error.localizedDescription)")
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onSave() // The onSave closure now also handles dismissal
                    }
                }
            }
            .onAppear {
                if !viewModel.isEditing {
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
    }
}
