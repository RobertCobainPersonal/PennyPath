import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AddTransactionViewModel

    var body: some View {
        NavigationView {
            Form {
                // Amount & Date
                Section(header: Text("Details")) {
                    TextField("Amount", value: $viewModel.amount, format: .currency(code: viewModel.currency))
                        .keyboardType(.decimalPad)

                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)

                    Picker("Type", selection: $viewModel.transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Account Picker
                Section(header: Text("Account")) {
                    Picker("From Account", selection: $viewModel.selectedAccountId) {
                        ForEach(viewModel.accounts, id: \.id) { account in
                            Text(account.name).tag(account.id ?? "")
                        }
                    }

                    if viewModel.transactionType == .transfer {
                        Picker("To Account", selection: $viewModel.destinationAccountId) {
                            ForEach(viewModel.accounts.filter { $0.id != viewModel.selectedAccountId }, id: \.id) { account in
                                Text(account.name).tag(account.id ?? "")
                            }
                        }
                    }
                }

                // Merchant, Category, Notes
                Section(header: Text("Information")) {
                    TextField("Merchant", text: $viewModel.merchant)
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category)
                        }
                    }
                    TextEditor(text: $viewModel.notes)
                }

                // Business Expense Toggle
                Section(header: Text("Flags")) {
                    Toggle("Business Expense", isOn: $viewModel.isBusinessExpense)
                    if viewModel.isBusinessExpense {
                        Button("Upload Receipt") {
                            viewModel.showImagePicker = true
                        }
                    }

                    Toggle("Part of Event", isOn: $viewModel.isEvent)
                    if viewModel.isEvent {
                        TextField("Event Name", text: $viewModel.eventName)
                    }

                    Toggle("BNPL Purchase", isOn: $viewModel.isBNPL)
                    if viewModel.isBNPL {
                        Picker("BNPL Plan", selection: $viewModel.selectedPlanId) {
                            ForEach(viewModel.bnplPlans, id: \.id) { plan in
                                Text(plan.name).tag(plan.id ?? "")
                            }
                        }
                        NavigationLink("Create New Plan") {
                            CreateBNPLPlanView(viewModel: viewModel.bnplPlanCreationViewModel)
                        }
                    }
                }
            }
            .navigationTitle("New Transaction")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveTransaction()
                        dismiss()
                    }
                    .disabled(!viewModel.isValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showImagePicker) {
                ImagePicker(image: $viewModel.receiptImage)
            }
        }
    }
}

// MARK: - Preview

struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddTransactionView(viewModel: AddTransactionViewModel.mockPreview())
    }
}

