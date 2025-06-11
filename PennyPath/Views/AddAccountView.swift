//
//  AddAccountView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: This view has been rebuilt to work with the simplified
//  Account model and the new AddAccountViewModel. It dynamically shows
//  fields based on the selected AccountType.
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
                // Section for common details across all account types
                Section(header: Text("General Information")) {
                    Picker("Account Type", selection: $viewModel.type) {
                        ForEach(AccountType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Account Name (e.g., Everyday Account)", text: $viewModel.name)
                    
                    // The label for institution changes for family loans
                    if viewModel.type == .familyLoan {
                        TextField("Person's Name", text: $viewModel.institution)
                    } else {
                        TextField("Institution (e.g., HSBC, Klarna)", text: $viewModel.institution)
                    }
                }
                
                // Section for core financial details
                Section(header: Text("Balance Details")) {
                    HStack {
                        Text("£")
                        TextField("Current Balance", text: $viewModel.currentBalanceStr)
                            .keyboardType(.decimalPad)
                    }
                }

                // --- Dynamically Shown Fields ---
                
                // Fields for Credit Card accounts
                if viewModel.type == .creditCard {
                    Section(header: Text("Credit Card Details")) {
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
                
                // Fields for Loan accounts
                if viewModel.type == .loan {
                    Section(header: Text("Loan Details")) {
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
                
                // Fields for BNPL accounts
                if viewModel.type == .bnpl {
                    Section(header: Text("BNPL Details")) {
                         HStack {
                            Text("£")
                            TextField("Outstanding Balance", text: $viewModel.outstandingBalanceStr)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                // Fields for Family/Friend Loan accounts
                if viewModel.type == .familyLoan {
                    Section(header: Text("Loan Details")) {
                        HStack {
                            Text("£")
                            TextField("Original Loan Amount", text: $viewModel.originalAmountStr)
                                .keyboardType(.decimalPad)
                        }
                         DatePicker("Date of Loan", selection: $viewModel.originationDate, displayedComponents: .date)
                    }
                }
                
                // Fields for Collection accounts
                if viewModel.type == .collectionAccount {
                     Section(header: Text("Collection Details")) {
                        TextField("Original Creditor (Optional)", text: $viewModel.originalCreditorStr)
                        HStack {
                           Text("£")
                           TextField("Settlement Amount (Optional)", text: $viewModel.settlementAmountStr)
                               .keyboardType(.decimalPad)
                       }
                    }
                }

                // Optional opening balance for any account type
                 Section(header: Text("Opening Balance (Optional)"), footer: Text("Set an opening balance if you want to import historical transactions later.")) {
                    HStack {
                        Text("£")
                        TextField("Opening Balance", text: $viewModel.openingBalanceStr)
                            .keyboardType(.decimalPad)
                    }
                    DatePicker("Date of Opening Balance", selection: $viewModel.openingBalanceDate, displayedComponents: .date)
                }

                // Save Button
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
