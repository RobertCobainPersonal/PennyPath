//
//  AddBNPLPlanViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: Fetches BNPL accounts to populate a picker.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AddBNPLPlanViewModel: ObservableObject {
    
    // MARK: - Form Input Fields
    @Published var provider: String = ""
    @Published var planName: String = ""
    // ... other fields are the same
    @Published var feeType: FeeType = .none
    @Published var feeValueStr: String = ""
    @Published var installmentsStr: String = "4"
    @Published var paymentFrequency: PaymentFrequency = .biweekly
    @Published var initialPaymentPercentStr: String = "25"
    
    // This is now the selected ID from the picker
    @Published var linkedAccountId: String = ""
    
    // MARK: - Data Sources
    @Published var bnplAccounts: [Account] = []
    
    // MARK: - State Management
    @Published var isLoading = false
    @Published var alertMessage: String?
    
    var isFormValid: Bool {
        !provider.trimmingCharacters(in: .whitespaces).isEmpty &&
        !planName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !installmentsStr.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init() {
        // Fetch accounts when the view model is created
        fetchBNPLAccounts()
    }
    
    // !! NEW !! - Fetches accounts of type 'bnpl'
    func fetchBNPLAccounts() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users/\(userId)/accounts")
            .whereField("type", isEqualTo: AccountType.bnpl.rawValue)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching BNPL accounts: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                self.bnplAccounts = documents.compactMap { try? $0.data(as: Account.self) }
            }
    }
    
    func savePlan() async {
        // ... (savePlan logic remains exactly the same)
        guard isFormValid else {
            alertMessage = "Please fill in all required fields: Provider, Plan Name, and Installments."
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "You must be logged in to save a plan."
            return
        }
        
        isLoading = true
        
        let feeValue = feeType == .none ? nil : Double(feeValueStr)
        guard let installments = Int(installmentsStr) else {
            alertMessage = "Please enter a valid number for installments."
            isLoading = false
            return
        }
        
        let initialPayment = initialPaymentPercentStr.isEmpty ? nil : Double(initialPaymentPercentStr)
        
        let newPlan = BNPLPlan(
            provider: provider,
            planName: planName,
            feeType: feeType,
            feeValue: feeValue,
            installments: installments,
            paymentFrequency: paymentFrequency,
            initialPaymentPercent: initialPayment,
            linkedAccountId: linkedAccountId.isEmpty ? nil : linkedAccountId
        )
        
        let db = Firestore.firestore()
        let collectionPath = "users/\(userId)/bnpl_plans"
        
        do {
            try db.collection(collectionPath).addDocument(from: newPlan)
            print("BNPL Plan successfully saved!")
            alertMessage = "Plan saved successfully!"
            isLoading = false
        } catch {
            print("Error saving BNPL plan: \(error.localizedDescription)")
            alertMessage = "Error: \(error.localizedDescription)"
            isLoading = false
        }
    }
}
