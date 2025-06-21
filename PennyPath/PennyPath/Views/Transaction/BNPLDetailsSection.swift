//
//  BNPLDetailsSection.swift
//  PennyPath
//
//  Created by Robert Cobain on 21/06/2025.
//

import SwiftUI

/// BNPL details section - appears after account selection when BNPL is enabled
/// No toggle here - just the provider, plan, and upfront fee fields
struct BNPLDetailsSection: View {
    @EnvironmentObject var appStore: AppStore
    @ObservedObject var formState: TransactionFormState
    
    // MARK: - State
    @State private var showingProviderPicker = false
    @State private var showingPlanPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BNPL Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // BNPL Provider Selection (auto-populated)
                bnplProviderField
                
                // BNPL Plan Selection (enabled only when provider is selected)
                bnplPlanField
                
                // Upfront Fee (optional)
                upfrontFeeField
                
                // Transaction Summary (when fields are populated)
                if !formState.bnplProvider.isEmpty && !formState.bnplPlan.isEmpty {
                    transactionSummary
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Individual Field Components
    
    private var bnplProviderField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BNPL Provider")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !formState.bnplProvider.isEmpty {
                    Spacer()
                    Text("Auto-filled from account")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Button(action: {
                showingProviderPicker = true
            }) {
                HStack {
                    if formState.bnplProvider.isEmpty {
                        Text("Select Provider")
                            .foregroundColor(.secondary)
                    } else {
                        Text(formState.bnplProvider)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    if !formState.bnplProvider.isEmpty {
                        Text("Change")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(formState.bnplProvider.isEmpty ? Color(.secondarySystemGroupedBackground) : Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            .sheet(isPresented: $showingProviderPicker) {
                BNPLProviderPickerSheet(selectedProvider: $formState.bnplProvider)
            }
        }
    }
    
    private var bnplPlanField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Plan")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Button(action: {
                if !formState.bnplProvider.isEmpty {
                    showingPlanPicker = true
                }
            }) {
                HStack {
                    if formState.bnplPlan.isEmpty {
                        Text(formState.bnplProvider.isEmpty ? "Select provider first" : "Select Plan")
                            .foregroundColor(.secondary)
                    } else {
                        Text(formState.bnplPlan)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(formState.bnplProvider.isEmpty ? Color(.tertiarySystemGroupedBackground) : Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            .disabled(formState.bnplProvider.isEmpty)
            .sheet(isPresented: $showingPlanPicker) {
                BNPLPlanPickerSheet(provider: formState.bnplProvider, selectedPlan: $formState.bnplPlan)
            }
        }
    }
    
    private var upfrontFeeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upfront Payment (Optional)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Amount paid today, if any")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("£")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $formState.upfrontFee)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: formState.upfrontFee) { newValue in
                        formState.upfrontFee = formatAmountInput(newValue)
                    }
                
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // Quick amount buttons for common upfront payments
            if formState.upfrontFee.isEmpty {
                InlineQuickAmounts(
                    selectedAmount: $formState.upfrontFee,
                    amounts: [10.0, 25.0, 50.0, 100.0]
                )
            }
        }
    }
    
    // MARK: - Transaction Summary
    
    private var transactionSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                
                Text("BNPL Summary")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                summaryRow(label: "Total Purchase", value: totalAmountFormatted)
                summaryRow(label: "Upfront Payment", value: upfrontFeeFormatted)
                summaryRow(label: "BNPL Amount", value: bnplAmountFormatted)
                summaryRow(label: "Payment Plan", value: formState.bnplPlan)
            }
            
            // Calculate Schedule Button (Phase 2)
            Button(action: {
                // TODO: Phase 2 - Calculate payment schedule
                print("🧮 Calculate schedule for \(formState.bnplProvider) \(formState.bnplPlan)")
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Calculate Payment Schedule")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isReadyForScheduleCalculation)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalAmountFormatted: String {
        guard let amount = Double(formState.amount), amount > 0 else { return "£0.00" }
        return amount.formattedAsCurrency
    }
    
    private var upfrontFeeFormatted: String {
        guard let fee = Double(formState.upfrontFee), fee > 0 else { return "£0.00" }
        return fee.formattedAsCurrency
    }
    
    private var bnplAmountFormatted: String {
        let total = Double(formState.amount) ?? 0
        let upfront = Double(formState.upfrontFee) ?? 0
        let bnplAmount = total - upfront
        return bnplAmount > 0 ? bnplAmount.formattedAsCurrency : "£0.00"
    }
    
    private var isReadyForScheduleCalculation: Bool {
        !formState.bnplProvider.isEmpty && 
        !formState.bnplPlan.isEmpty && 
        (Double(formState.amount) ?? 0) > 0
    }
    
    // MARK: - Helper Methods
    
    private func formatAmountInput(_ input: String) -> String {
        let filtered = input.filter { $0.isNumber || $0 == "." }
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1]
        }
        if components.count == 2 && components[1].count > 2 {
            return components[0] + "." + String(components[1].prefix(2))
        }
        return filtered
    }
}

// MARK: - BNPL Provider Picker Sheet

struct BNPLProviderPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedProvider: String
    
    // UK BNPL providers
    private let providers = [
        "Klarna", "Clearpay", "Laybuy", "PayPal Pay in 3", 
        "Zilch", "Butter", "Sezzle", "Other"
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(providers, id: \.self) { provider in
                    Button(action: {
                        selectedProvider = provider
                        dismiss()
                    }) {
                        HStack {
                            Text(provider)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedProvider == provider {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("BNPL Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - BNPL Plan Picker Sheet

struct BNPLPlanPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let provider: String
    @Binding var selectedPlan: String
    
    private var availablePlans: [String] {
        switch provider {
        case "Klarna":
            return ["Pay in 3 (0% interest)", "Pay in 30 days", "Slice it (6-24 months)"]
        case "Clearpay":
            return ["Pay in 4 fortnightly", "Pay in 4 weekly"]
        case "Laybuy":
            return ["Pay in 6 weekly"]
        case "PayPal Pay in 3":
            return ["Pay in 3 monthly"]
        case "Zilch":
            return ["Pay over 4 weeks", "Pay over 6 weeks"]
        default:
            return ["Custom plan"]
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availablePlans, id: \.self) { plan in
                    Button(action: {
                        selectedPlan = plan
                        dismiss()
                    }) {
                        HStack {
                            Text(plan)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedPlan == plan {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(provider) Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview Provider
struct BNPLDetailsSection_Previews: PreviewProvider {
    static var previews: some View {
        let formState = TransactionFormState()
        formState.isBNPLPurchase = true
        formState.bnplProvider = "Klarna"
        formState.bnplPlan = "Pay in 3 (0% interest)"
        formState.amount = "299.99"
        formState.upfrontFee = "25.00"
        
        return ScrollView {
            VStack(spacing: 20) {
                BNPLDetailsSection(formState: formState)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .environmentObject(AppStore())
    }
}
