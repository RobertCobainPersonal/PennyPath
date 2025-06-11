//
//  AddBNPLPlanView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: Replaced TextField with a Picker for Default Linked Account.
//

import SwiftUI

struct AddBNPLPlanView: View {
    
    @StateObject private var viewModel = AddBNPLPlanViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // ... (Plan Details, Fee Structure, Repayment Schedule sections are the same)
                Section(header: Text("Plan Details")) {
                    TextField("Provider (e.g., Klarna, Zilch)", text: $viewModel.provider)
                    TextField("Plan Name (e.g., Pay in 3)", text: $viewModel.planName)
                }
                
                Section(header: Text("Fee Structure")) {
                    Picker("Fee Type", selection: $viewModel.feeType) {
                        ForEach(FeeType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if viewModel.feeType != .none {
                        HStack {
                            TextField("Fee Value", text: $viewModel.feeValueStr)
                                .keyboardType(.decimalPad)
                            if viewModel.feeType == .flat {
                                Text("£")
                            } else if viewModel.feeType == .percentage {
                                Text("%")
                            }
                        }
                    }
                }
                
                Section(header: Text("Repayment Schedule")) {
                    Picker("Payment Frequency", selection: $viewModel.paymentFrequency) {
                        ForEach(PaymentFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    Stepper("\(viewModel.installmentsStr) Installments",
                            text: $viewModel.installmentsStr)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Initial Payment (Optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            TextField("e.g., 25", text: $viewModel.initialPaymentPercentStr)
                                .keyboardType(.numberPad)
                            Text("%")
                        }
                    }
                }
                
                // !! UPDATED SECTION !!
                Section(header: Text("Optional Settings")) {
                    Picker("Default Linked Account", selection: $viewModel.linkedAccountId) {
                        Text("None").tag("") // Allow user to select no default
                        ForEach(viewModel.bnplAccounts) { account in
                            Text(account.name).tag(account.id ?? "")
                        }
                    }
                }
                
                // ... (Save button section is the same)
                Section {
                    Button(action: {
                        Task {
                            await viewModel.savePlan()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Save Plan")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Create BNPL Plan")
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
            .onChange(of: viewModel.alertMessage) { message in
                if message != nil {
                    showingAlert = true
                }
            }
            .alert("BNPL Plan", isPresented: $showingAlert, actions: {
                Button("OK") {
                    if viewModel.alertMessage == "Plan saved successfully!" {
                        dismiss()
                    }
                    viewModel.alertMessage = nil
                }
            }, message: {
                Text(viewModel.alertMessage ?? "An unknown error occurred.")
            })
        }
    }
}

// A simple stepper that works directly with a String binding
struct Stepper: View {
    let title: String
    @Binding var text: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        SwiftUI.Stepper(
            title,
            onIncrement: {
                text = "\(Int(text) ?? 0 + 1)"
            },
            onDecrement: {
                let value = Int(text) ?? 0
                if value > 1 {
                    text = "\(value - 1)"
                }
            }
        )
    }
}


struct AddBNPLPlanView_Previews: PreviewProvider {
    static var previews: some View {
        AddBNPLPlanView()
    }
}
