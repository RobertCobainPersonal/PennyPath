//
//  AddTransferView.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import SwiftUI

struct AddTransferView: View {
    @StateObject private var viewModel = AddTransferViewModel()
    @EnvironmentObject var store: AppStore
    var onSave: () -> Void

    private var fromAccount: Account? {
        store.accounts.first { $0.id == viewModel.fromAccountId }
    }
    
    private var toAccount: Account? {
        store.accounts.first { $0.id == viewModel.toAccountId }
    }

    var body: some View {
        Form {
            Section(header: Text("Transfer Details")) {
                TextField("Amount", text: $viewModel.amountStr)
                    .keyboardType(.decimalPad)
                DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                TextField("Description", text: $viewModel.description)
            }
            
            Section(header: Text("Accounts")) {
                Picker("From", selection: $viewModel.fromAccountId) {
                    ForEach(store.accounts) { account in
                        Text(account.name).tag(account.id ?? "")
                    }
                }
                
                Picker("To", selection: $viewModel.toAccountId) {
                    ForEach(store.accounts.filter { $0.id != viewModel.fromAccountId }) { account in
                        Text(account.name).tag(account.id ?? "")
                    }
                }
            }
            
            Section {
                Button("Save Transfer") {
                    Task {
                        guard let from = fromAccount, let to = toAccount else {
                            print("Error: Could not find selected accounts.")
                            return
                        }
                        
                        do {
                            try await viewModel.save(fromAccount: from, toAccount: to)
                            onSave()
                        } catch {
                            print("Error saving transfer: \(error.localizedDescription)")
                        }
                    }
                }
                .disabled(!viewModel.isFormValid)
            }
        }
        .onAppear {
            if viewModel.fromAccountId.isEmpty, let fromAccount = store.accounts.first {
                viewModel.fromAccountId = fromAccount.id ?? ""
            }
            if viewModel.toAccountId.isEmpty, let toAccount = store.accounts.first(where: { $0.id != viewModel.fromAccountId }) {
                viewModel.toAccountId = toAccount.id ?? ""
            }
        }
        .onChange(of: viewModel.fromAccountId) {
            // If the 'from' and 'to' accounts are now the same...
            if viewModel.fromAccountId == viewModel.toAccountId {
                // ...reset the 'to' account to the first valid option.
                if let newToAccount = store.accounts.first(where: { $0.id != viewModel.fromAccountId }) {
                    viewModel.toAccountId = newToAccount.id ?? ""
                }
            }
        }
    }
}


struct AddTransferView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStore = AppStore()
        
        let sampleAccount1 = Account(name: "Current Account", type: .currentAccount, institution: "Monzo", currentBalance: 1500)
        let sampleAccount2 = Account(name: "Savings", type: .savings, institution: "HSBC", currentBalance: 5000)
        
        mockStore.accounts = [sampleAccount1, sampleAccount2]
        
        return AddTransferView(onSave: {})
            .environmentObject(mockStore)
    }
}
