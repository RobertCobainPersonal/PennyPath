//
//  EditAccountView.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

struct EditAccountView: View {
    @EnvironmentObject var appStore: AppStore
    @Environment(\.dismiss) private var dismiss
    
    let originalAccount: Account
    
    // Form state
    @State private var accountName: String
    @State private var creditLimit: String
    @State private var originalLoanAmount: String
    @State private var loanTermMonths: String
    @State private var loanStartDate: Date
    @State private var interestRate: String
    @State private var monthlyPayment: String
    @State private var bnplProvider: String
    
    @State private var showingDeleteConfirmation = false
    @State private var deletionImpact: AccountDeletionImpact?
    
    init(account: Account) {
        self.originalAccount = account
        
        // Initialize form state
        self._accountName = State(initialValue: account.name)
        self._creditLimit = State(initialValue: account.creditLimit?.description ?? "")
        self._originalLoanAmount = State(initialValue: account.originalLoanAmount?.description ?? "")
        self._loanTermMonths = State(initialValue: account.loanTermMonths?.description ?? "")
        self._loanStartDate = State(initialValue: account.loanStartDate ?? Date())
        self._interestRate = State(initialValue: account.interestRate?.description ?? "")
        self._monthlyPayment = State(initialValue: account.monthlyPayment?.description ?? "")
        self._bnplProvider = State(initialValue: account.bnplProvider ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic account information
                Section("Account Details") {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: originalAccount.type.color).opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: originalAccount.type.icon)
                                .font(.headline)
                                .foregroundColor(Color(hex: originalAccount.type.color))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(originalAccount.type.displayName)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text("Account Type")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    TextField("Account Name", text: $accountName)
                        .textInputAutocapitalization(.words)
                }
                
                // Account-specific fields
                accountSpecificFields
                
                // Danger zone
                Section {
                    Button("Delete Account", role: .destructive) {
                        deletionImpact = appStore.getDeletionImpact(for: originalAccount)
                        showingDeleteConfirmation = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Deleting this account will permanently remove all associated transactions, transfers, and payment plans. This action cannot be undone.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAccount()
                    }
                    .fontWeight(.semibold)
                    .disabled(accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let impact = deletionImpact {
                    appStore.deleteAccount(impact.account)
                    dismiss()
                }
            }
        } message: {
            if let impact = deletionImpact {
                Text("This will permanently delete \"\(impact.account.name)\" and cannot be undone.\n\n\(impact.impactDescription)")
            }
        }
    }
    
    // MARK: - Account-Specific Fields
    
    @ViewBuilder
    private var accountSpecificFields: some View {
        switch originalAccount.type {
        case .credit:
            creditCardFields
        case .loan:
            loanFields
        case .bnpl:
            bnplFields
        default:
            EmptyView()
        }
    }
    
    private var creditCardFields: some View {
        Section("Credit Card Information") {
            HStack {
                Text("Credit Limit")
                Spacer()
                TextField("£0.00", text: $creditLimit)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
            
            if let limit = Double(creditLimit), let currentBalance = originalAccount.balance as Double?, limit > 0 {
                let utilization = abs(currentBalance) / limit
                HStack {
                    Text("Current Utilization")
                    Spacer()
                    Text("\(Int(utilization * 100))%")
                        .foregroundColor(utilization > 0.7 ? .red : utilization > 0.3 ? .orange : .green)
                }
            }
        }
    }
    
    private var loanFields: some View {
        Section("Loan Information") {
            HStack {
                Text("Original Amount")
                Spacer()
                TextField("£0.00", text: $originalLoanAmount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
            
            HStack {
                Text("Term (Months)")
                Spacer()
                TextField("48", text: $loanTermMonths)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 60)
            }
            
            DatePicker("Start Date", selection: $loanStartDate, displayedComponents: .date)
            
            HStack {
                Text("Interest Rate (%)")
                Spacer()
                TextField("5.9", text: $interestRate)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 60)
            }
            
            HStack {
                Text("Monthly Payment")
                Spacer()
                TextField("£0.00", text: $monthlyPayment)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
        }
    }
    
    private var bnplFields: some View {
        Section("BNPL Information") {
            HStack {
                Text("Provider")
                Spacer()
                TextField("Klarna, Clearpay, etc.", text: $bnplProvider)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 150)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveAccount() {
        // Create updated account with new values
        let updatedAccount = Account(
            id: originalAccount.id,
            userId: originalAccount.userId,
            name: accountName.trimmingCharacters(in: .whitespacesAndNewlines),
            type: originalAccount.type,
            balance: originalAccount.balance,
            creditLimit: originalAccount.type == .credit ? Double(creditLimit) : originalAccount.creditLimit,
            originalLoanAmount: originalAccount.type == .loan ? Double(originalLoanAmount) : originalAccount.originalLoanAmount,
            loanTermMonths: originalAccount.type == .loan ? Int(loanTermMonths) : originalAccount.loanTermMonths,
            loanStartDate: originalAccount.type == .loan ? loanStartDate : originalAccount.loanStartDate,
            interestRate: originalAccount.type == .loan ? Double(interestRate) : originalAccount.interestRate,
            monthlyPayment: originalAccount.type == .loan ? Double(monthlyPayment) : originalAccount.monthlyPayment,
            bnplProvider: originalAccount.type == .bnpl ? (bnplProvider.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bnplProvider.trimmingCharacters(in: .whitespacesAndNewlines)) : originalAccount.bnplProvider,
            createdAt: originalAccount.createdAt  // Preserve original creation date
        )
        
        appStore.updateAccount(updatedAccount)
        dismiss()
    }
}

// MARK: - Preview Provider
struct EditAccountView_Previews: PreviewProvider {
    static var previews: some View {
        EditAccountView(account: Account(
            userId: "test",
            name: "Santander Credit Card",
            type: .credit,
            balance: -892.45,
            creditLimit: 3000.00
        ))
        .environmentObject(AppStore())
    }
}
