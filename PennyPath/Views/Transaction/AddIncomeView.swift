//
//  AddIncomeView.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//


//
//  AddIncomeView.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import SwiftUI

struct AddIncomeView: View {
    @StateObject private var viewModel = AddIncomeViewModel()
    @EnvironmentObject var store: AppStore
    var onSave: () -> Void

    var body: some View {
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
                Button("Save Income") {
                    Task {
                        do {
                            try await viewModel.save()
                            onSave()
                        } catch {
                            print("Error saving income: \(error.localizedDescription)")
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
        }
    }
}