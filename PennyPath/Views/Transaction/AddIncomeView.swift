//
//  AddIncomeView.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import SwiftUI

struct AddIncomeView: View {
    // ViewModel is now passed in
    @StateObject private var viewModel: AddIncomeViewModel
    @EnvironmentObject var store: AppStore
    var onSave: () -> Void

    // New initializer
    init(viewModel: AddIncomeViewModel, onSave: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        // We wrap the form in a NavigationView so it gets a title bar in the sheet
        NavigationView {
            Form {
                Section(header: Text("Income Details")) {
                    TextField("Amount", text: $viewModel.amountStr)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    TextField("Description (e.g., Salary, Refund)", text: $viewModel.description)
                }
                
                Section(header: Text("Account")) {
                    Picker("Deposit to Account", selection: $viewModel.selectedAccountId) {
                        ForEach(store.accounts) { account in
                            Text(account.name).tag(account.id ?? "")
                        }
                    }
                }
                
                Section {
                    Button(viewModel.saveButtonText) {
                        Task {
                            do {
                                try await viewModel.saveOrUpdate()
                                onSave()
                            } catch {
                                print("Error saving income: \(error.localizedDescription)")
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
                        onSave()
                    }
                }
            }
            .onAppear {
                if !viewModel.isEditing {
                    if viewModel.selectedAccountId.isEmpty, let account = store.accounts.first {
                        viewModel.selectedAccountId = account.id ?? ""
                    }
                }
            }
        }
    }
}
