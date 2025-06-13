//
//  AddAccountView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: The UI has been simplified to align with the new
//  'anchorBalance' architecture. It now asks for a single initial
//  balance and date.
//

import SwiftUI
import FirebaseFirestore

struct AddAccountView: View {
    
    @StateObject private var viewModel = AddAccountViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General Information")) {
                    Picker("Account Type", selection: $viewModel.type.animation()) {
                        ForEach(AccountType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Account Name (e.g., Everyday Account)", text: $viewModel.name)
                    
                    if viewModel.type == .familyLoan {
                        TextField("Person's Name (Optional)", text: $viewModel.institution)
                    } else {
                        TextField("Institution (e.g., HSBC, Klarna) (Optional)", text: $viewModel.institution)
                    }
                }
                
                Section(header: Text("Starting Balance")) {
                    HStack {
                        Text("£")
                        let balanceLabel = viewModel.type.isCredit ? "Balance as of Date (Amount Owed)" : "Balance as of Date"
                        TextField(balanceLabel, text: $viewModel.initialBalanceStr)
                            .keyboardType(.decimalPad)
                    }
                    DatePicker("Date of Balance", selection: $viewModel.dateOfBalance, displayedComponents: .date)
                }

                // --- Dynamically Shown Fields for Credit Accounts ---
                
                if viewModel.type == .creditCard {
                    Section(header: Text("Credit Card Details (Optional)")) {
                        HStack {
                            Text("£")
                            TextField("Credit Limit", text: $viewModel.creditLimitStr)
                                .keyboardType(.decimalPad)
                        }
                        HStack {
                            TextField("APR", text: $viewModel.aprStr)
                                .keyboardType(.decimalPad)
                            Text("%")
                        }
                    }
                }
                
                if viewModel.type == .loan || viewModel.type == .familyLoan {
                    Section(header: Text("Loan Details (Optional)")) {
                        HStack {
                            Text("£")
                            TextField("Original Loan Amount", text: $viewModel.originalAmountStr)
                                .keyboardType(.decimalPad)
                        }
                        HStack {
                            TextField("Interest Rate", text: $viewModel.interestRateStr)
                                .keyboardType(.decimalPad)
                            Text("%")
                        }
                        DatePicker("Loan Origination Date", selection: $viewModel.originationDate, displayedComponents: .date)
                    }
                }
                
                if viewModel.type == .collectionAccount {
                     Section(header: Text("Collection Details (Optional)")) {
                        TextField("Original Creditor", text: $viewModel.originalCreditorStr)
                        HStack {
                           Text("£")
                           TextField("Settlement Amount", text: $viewModel.settlementAmountStr)
                               .keyboardType(.decimalPad)
                       }
                    }
                }

                // --- Save Button ---
                Section {
                    Button(action: {
                        Task { await viewModel.saveAccount() }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Save Account")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Add New Account")
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
            .onChange(of: viewModel.alertMessage) { message in
                if message != nil { showingAlert = true }
            }
            .alert("Add Account", isPresented: $showingAlert, actions: {
                Button("OK") {
                    if viewModel.alertMessage == "Account saved successfully!" {
                        dismiss()
                    }
                    viewModel.alertMessage = nil
                }
            }, message: {
                Text(viewModel.alertMessage ?? "An error occurred.")
            })
        }
    }
}


struct AddAccountView_Previews: PreviewProvider {
    static var previews: some View {
        AddAccountView()
    }
}
