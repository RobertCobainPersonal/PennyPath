//
//  BNPLDetailsSection.swift
//  PennyPath
//
//  Created by Robert Cobain on 21/06/2025.
//  Enhanced with correct calculations and payment schedule functionality
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
    @State private var showingPaymentSchedule = false
    
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
        .sheet(isPresented: $showingProviderPicker) {
            BNPLProviderPickerSheet(selectedProvider: $formState.bnplProvider)
        }
        .sheet(isPresented: $showingPlanPicker) {
            BNPLPlanPickerSheet(provider: formState.bnplProvider, selectedPlan: $formState.bnplPlan)
        }
        .sheet(isPresented: $showingPaymentSchedule) {
            PaymentScheduleSheet(
                purchaseAmount: Double(formState.amount) ?? 0,
                upfrontFee: Double(formState.upfrontFee) ?? 0,
                provider: formState.bnplProvider,
                plan: formState.bnplPlan,
                payments: generatePaymentSchedule()
            )
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
                // Quick amount buttons - simplified for now
                HStack(spacing: 8) {
                    ForEach([10.0, 25.0, 50.0, 100.0], id: \.self) { amount in
                        Button("\(Int(amount))") {
                            formState.upfrontFee = String(format: "%.0f", amount)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
    
    // MARK: - Transaction Summary (UPDATED WITH FIXED CALCULATIONS)
    
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
                summaryRow(label: "Purchase Amount", value: totalAmountFormatted)
                
                if (Double(formState.upfrontFee) ?? 0) > 0 {
                    summaryRow(label: "Upfront Fee", value: upfrontFeeFormatted)
                    
                    Divider()
                    
                    summaryRow(label: "Total Cost", value: totalCostFormatted, isTotal: true)
                    
                    Divider()
                }
                
                summaryRow(label: "BNPL Amount", value: bnplAmountFormatted)
                summaryRow(label: "Payment Plan", value: formState.bnplPlan)
                
                if let breakdown = calculatePaymentBreakdown() {
                    summaryRow(label: "Number of Payments", value: "\(breakdown.numberOfPayments)")
                    summaryRow(label: "Payment Amount", value: breakdown.paymentAmount.formattedAsCurrency)
                }
            }
            
            // Calculate Schedule Button
            Button(action: {
                showPaymentSchedule()
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("View Payment Schedule")
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
    
    private func summaryRow(label: String, value: String, isTotal: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(isTotal ? .semibold : .regular)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(isTotal ? .bold : .medium)
                .foregroundColor(isTotal ? .blue : .primary)
        }
    }
    
    // MARK: - Computed Properties (FIXED CALCULATIONS)
    
    private var totalAmountFormatted: String {
        guard let amount = Double(formState.amount), amount > 0 else { return "£0.00" }
        return amount.formattedAsCurrency
    }
    
    private var upfrontFeeFormatted: String {
        guard let fee = Double(formState.upfrontFee), fee > 0 else { return "£0.00" }
        return fee.formattedAsCurrency
    }
    
    // FIXED: BNPL amount is the purchase amount (fee is additional cost)
    private var bnplAmountFormatted: String {
        let purchaseAmount = Double(formState.amount) ?? 0
        return purchaseAmount > 0 ? purchaseAmount.formattedAsCurrency : "£0.00"
    }
    
    // NEW: Total cost calculation (purchase + fee)
    private var totalCostFormatted: String {
        let purchaseAmount = Double(formState.amount) ?? 0
        let upfrontFee = Double(formState.upfrontFee) ?? 0
        let totalCost = purchaseAmount + upfrontFee
        return totalCost.formattedAsCurrency
    }
    
    private var isReadyForScheduleCalculation: Bool {
        !formState.bnplProvider.isEmpty &&
        !formState.bnplPlan.isEmpty &&
        (Double(formState.amount) ?? 0) > 0
    }
    
    // MARK: - Payment Schedule Logic
    
    private func showPaymentSchedule() {
        showingPaymentSchedule = true
    }
    
    private func calculatePaymentBreakdown() -> PaymentBreakdown? {
        guard let purchaseAmount = Double(formState.amount),
              purchaseAmount > 0,
              !formState.bnplPlan.isEmpty else { return nil }
        
        let numberOfPayments = getNumberOfPayments(for: formState.bnplPlan)
        let paymentAmount = purchaseAmount / Double(numberOfPayments)
        
        return PaymentBreakdown(
            numberOfPayments: numberOfPayments,
            paymentAmount: paymentAmount
        )
    }
    
    private func getNumberOfPayments(for plan: String) -> Int {
        switch plan.lowercased() {
        case let p where p.contains("pay in 3"):
            return 3
        case let p where p.contains("pay in 4"):
            return 4
        case let p where p.contains("pay in 6"):
            return 6
        case let p where p.contains("4 weeks"):
            return 4
        case let p where p.contains("6 weeks"):
            return 6
        case let p where p.contains("30 days"):
            return 1
        default:
            return 3 // Default fallback
        }
    }
    
    private func getPaymentFrequency(for plan: String) -> PaymentFrequency {
        switch plan.lowercased() {
        case let p where p.contains("weekly"):
            return .weekly
        case let p where p.contains("fortnightly"):
            return .biweekly
        case let p where p.contains("monthly"):
            return .monthly
        case let p where p.contains("weeks"):
            return .weekly
        case let p where p.contains("30 days"):
            return .monthly
        default:
            return .biweekly // Default for most BNPL
        }
    }
    
    private func generatePaymentSchedule() -> [BNPLScheduledPayment] {
        guard let purchaseAmount = Double(formState.amount),
              let breakdown = calculatePaymentBreakdown() else { return [] }
        
        let upfrontFee = Double(formState.upfrontFee) ?? 0
        let frequency = getPaymentFrequency(for: formState.bnplPlan)
        
        var payments: [BNPLScheduledPayment] = []
        let calendar = Calendar.current
        let startDate = Date()
        
        // Add upfront fee payment if exists
        if upfrontFee > 0 {
            payments.append(BNPLScheduledPayment(
                id: UUID().uuidString,
                date: startDate,
                amount: upfrontFee,
                description: "Upfront Fee - \(formState.bnplProvider)",
                type: BNPLScheduledPayment.PaymentType.upfrontFee
            ))
        }
        
        // Add installment payments
        for i in 1...breakdown.numberOfPayments {
            let paymentDate: Date
            
            switch frequency {
            case .daily:
                paymentDate = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            case .weekly:
                paymentDate = calendar.date(byAdding: .weekOfYear, value: i, to: startDate) ?? startDate
            case .biweekly:
                paymentDate = calendar.date(byAdding: .weekOfYear, value: i * 2, to: startDate) ?? startDate
            case .monthly:
                paymentDate = calendar.date(byAdding: .month, value: i, to: startDate) ?? startDate
            case .yearly:
                paymentDate = calendar.date(byAdding: .year, value: i, to: startDate) ?? startDate
            }
            
            payments.append(BNPLScheduledPayment(
                id: UUID().uuidString,
                date: paymentDate,
                amount: breakdown.paymentAmount,
                description: "Payment \(i) of \(breakdown.numberOfPayments)",
                type: BNPLScheduledPayment.PaymentType.installment(i)
            ))
        }
        
        return payments.sorted { $0.date < $1.date }
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

// MARK: - Payment Schedule Sheet

struct PaymentScheduleSheet: View {
    @Environment(\.dismiss) private var dismiss
    let purchaseAmount: Double
    let upfrontFee: Double
    let provider: String
    let plan: String
    @State private var payments: [BNPLScheduledPayment]
    
    init(purchaseAmount: Double, upfrontFee: Double, provider: String, plan: String, payments: [BNPLScheduledPayment]) {
        self.purchaseAmount = purchaseAmount
        self.upfrontFee = upfrontFee
        self.provider = provider
        self.plan = plan
        self._payments = State(initialValue: payments)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(provider) - \(plan)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Purchase: \(purchaseAmount.formattedAsCurrency)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if upfrontFee > 0 {
                                Text("Fee: \(upfrontFee.formattedAsCurrency)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Total Cost")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text((purchaseAmount + upfrontFee).formattedAsCurrency)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Payment List
                List {
                    ForEach(payments) { payment in
                        PaymentRowView(payment: payment) { updatedPayment in
                            if let index = payments.firstIndex(where: { $0.id == updatedPayment.id }) {
                                payments[index] = updatedPayment
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Payment Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Schedule") {
                        // TODO: Save the schedule
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Payment Row View

struct PaymentRowView: View {
    let payment: BNPLScheduledPayment
    let onUpdate: (BNPLScheduledPayment) -> Void
    
    @State private var showingDatePicker = false
    @State private var tempDate: Date
    
    init(payment: BNPLScheduledPayment, onUpdate: @escaping (BNPLScheduledPayment) -> Void) {
        self.payment = payment
        self.onUpdate = onUpdate
        self._tempDate = State(initialValue: payment.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(payment.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(payment.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                            Image(systemName: "pencil")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(payment.amount.formattedAsCurrency)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(paymentTypeText)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(paymentTypeColor.opacity(0.2))
                        .foregroundColor(paymentTypeColor)
                        .cornerRadius(4)
                }
            }
            
            if case .installment = payment.type {
                // Progress indicator
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(date: $tempDate) { newDate in
                let updatedPayment = BNPLScheduledPayment(
                    id: payment.id,
                    date: newDate,
                    amount: payment.amount,
                    description: payment.description,
                    type: payment.type
                )
                onUpdate(updatedPayment)
            }
        }
    }
    
    private var paymentTypeText: String {
        switch payment.type {
        case .upfrontFee:
            return "FEE"
        case .installment(let number):
            return "PAYMENT \(number)"
        }
    }
    
    private var paymentTypeColor: Color {
        switch payment.type {
        case .upfrontFee:
            return .orange
        case .installment:
            return .blue
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    let onSave: (Date) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Payment Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(date)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Supporting Data Structures

struct PaymentBreakdown {
    let numberOfPayments: Int
    let paymentAmount: Double
}

struct BNPLScheduledPayment: Identifiable {
    let id: String
    let date: Date
    let amount: Double
    let description: String
    let type: PaymentType
    
    enum PaymentType {
        case upfrontFee
        case installment(Int)
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
