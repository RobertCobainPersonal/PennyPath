//
//  AddTransactionViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// A simple struct to hold the calculated results of a BNPL plan for UI preview.
struct BNPLSchedulePreview {
    let initialPayment: Double
    let fee: Double
    let installmentAmount: Double
    let remainingBalance: Double
    let schedule: [(date: Date, amount: Double)]
}

@MainActor
class AddTransactionViewModel: ObservableObject {
    
    // MARK: - Form Input Fields
    @Published var amountStr: String = ""
    @Published var selectedAccountId: String = ""
    @Published var selectedDate: Date = Date()
    @Published var category: String = ""
    @Published var description: String = ""
    @Published var isBNPL: Bool = false
    
    // BNPL-specific fields
    @Published var selectedPlanId: String = ""
    @Published var selectedFundingAccountId: String = ""
    
    // MARK: - Data Sources for Pickers
    @Published var userAccounts = [Account]()
    @Published var userBNPLPlans = [BNPLPlan]()
    
    // MARK: - State Management
    @Published var isLoading = false
    @Published var alertMessage: String?
    
    // ... (All computed properties like selectedPlan, amount, schedulePreview remain the same) ...
    var selectedPlan: BNPLPlan? {
        userBNPLPlans.first { $0.id == selectedPlanId }
    }
    
    var amount: Double {
        Double(amountStr) ?? 0.0
    }
    
    var schedulePreview: BNPLSchedulePreview? {
        guard isBNPL, let plan = selectedPlan, amount > 0 else {
            return nil
        }
        
        let fee = calculateFee(for: plan, amount: amount)
        let totalDebt = amount + fee
        let initialPaymentPercent = (plan.initialPaymentPercent ?? 0) / 100
        let initialPayment = totalDebt * initialPaymentPercent
        let remainingBalance = totalDebt - initialPayment
        let installmentAmount = remainingBalance / Double(plan.installments)
        
        var paymentDates = [Date]()
        var currentDate = selectedDate
        for _ in 0..<plan.installments {
            currentDate = calculateNextDueDate(from: currentDate, frequency: plan.paymentFrequency)
            paymentDates.append(currentDate)
        }
        let schedule = paymentDates.map { (date: $0, amount: installmentAmount) }
        
        return BNPLSchedulePreview(
            initialPayment: initialPayment, fee: fee, installmentAmount: installmentAmount,
            remainingBalance: remainingBalance, schedule: schedule
        )
    }

    var isFormValid: Bool {
        !amountStr.isEmpty && !selectedAccountId.isEmpty && (isBNPL ? !selectedPlanId.isEmpty && !selectedFundingAccountId.isEmpty : true)
    }

    private var db = Firestore.firestore()
    
    init() {
        fetchPrerequisites()
    }
    
    func fetchPrerequisites() {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            // Fetch accounts
            db.collection("users/\(userId)/accounts").getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.userAccounts = documents.compactMap { try? $0.data(as: Account.self) }
                if let firstAccountId = self.userAccounts.first?.id {
                    self.selectedAccountId = firstAccountId
                }
            }
            
            // Fetch BNPL plans
            db.collection("users/\(userId)/bnpl_plans").getDocuments { snapshot, error in
                // !! DEBUGGING LINE !!
                print("Fetching BNPL plans...")
                
                guard let documents = snapshot?.documents else {
                    print("Error or no documents found for BNPL plans.")
                    return
                }
                
                self.userBNPLPlans = documents.compactMap { try? $0.data(as: BNPLPlan.self) }
                
                // !! DEBUGGING LINE !!
                print("Found \(self.userBNPLPlans.count) BNPL plans.")
                
                if let firstPlanId = self.userBNPLPlans.first?.id {
                    self.selectedPlanId = firstPlanId
                }
            }
        }
    
    // MARK: - Save Logic (Now using the Service)
    
    func saveTransaction() async {
        guard isFormValid, let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "Please fill all required fields."
            return
        }
        
        isLoading = true
        
        // Assemble the details struct to pass to the service.
        let details = TransactionDetails(
            amount: amount,
            accountId: selectedAccountId,
            date: selectedDate,
            description: description,
            category: category,
            isBNPL: isBNPL,
            bnplPlan: selectedPlan,
            bnplFundingAccountId: selectedFundingAccountId,
            bnplSchedule: schedulePreview
        )
        
        do {
            // Call the shared TransactionService.
            try await TransactionService.shared.addTransaction(details: details, for: userId)
            alertMessage = "Transaction saved successfully!"
        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // ... (private helper methods for calculation remain the same) ...
    private func calculateFee(for plan: BNPLPlan, amount: Double) -> Double {
        guard let feeValue = plan.feeValue else { return 0 }
        switch plan.feeType {
        case .none:
            return 0
        case .flat:
            return feeValue
        case .percentage:
            return amount * (feeValue / 100)
        }
    }
    
    private func calculateNextDueDate(from startDate: Date, frequency: PaymentFrequency) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate)!
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: startDate)!
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate)!
        }
    }
}
