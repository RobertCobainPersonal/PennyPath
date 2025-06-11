//
//  ScheduledPaymentsViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - ViewModel

@MainActor
class ScheduledPaymentsViewModel: ObservableObject {
    
    /// Holds the upcoming payments, grouped by a string representation of the due date section (e.g., "This Week").
    @Published var groupedPayments = [String: [ScheduledPayment]]()
    /// A simple lookup to display account names instead of just IDs.
    @Published var accountNameLookup = [String: String]()
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var paymentsListener: ListenerRegistration?
    private var accountsListener: ListenerRegistration?

    init() {
        // Start fetching data as soon as the ViewModel is created.
        fetchData()
    }
    
    deinit {
        // Ensure we remove listeners when the view is no longer in use.
        paymentsListener?.remove()
        accountsListener?.remove()
        print("ScheduledPaymentsViewModel deinitialized and listeners removed.")
    }

    /// Fetches both accounts (for name lookups) and scheduled payments.
    func fetchData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            isLoading = false
            return
        }
        
        fetchAccountNames(userId: userId)
        fetchScheduledPayments(userId: userId)
    }

    /// Fetches all of the user's accounts to create a simple ID-to-Name dictionary.
    private func fetchAccountNames(userId: String) {
        let accountsPath = "users/\(userId)/accounts"
        accountsListener = db.collection(accountsPath).addSnapshotListener { querySnapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch accounts: \(error.localizedDescription)"
                return
            }
            guard let documents = querySnapshot?.documents else { return }
            
            var lookup = [String: String]()
            for doc in documents {
                if let id = doc.documentID as String?, let name = doc.data()["name"] as? String {
                    lookup[id] = name
                }
            }
            self.accountNameLookup = lookup
        }
    }
    
    /// Fetches all unpaid, upcoming payments and listens for real-time updates.
    private func fetchScheduledPayments(userId: String) {
        isLoading = true
        let paymentsPath = "users/\(userId)/scheduled_payments"
        
        // Create a Timestamp for the beginning of today to use in the query.
        let today = Timestamp(date: Calendar.current.startOfDay(for: Date()))
        
        paymentsListener = db.collection(paymentsPath)
            .whereField("paid", isEqualTo: false)
            .whereField("dueDate", isGreaterThanOrEqualTo: today)
            .order(by: "dueDate", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Failed to fetch payments: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                let payments = documents.compactMap { doc -> ScheduledPayment? in
                    try? doc.data(as: ScheduledPayment.self)
                }
                
                self.groupPayments(payments)
                self.isLoading = false
            }
    }

    /// Marks a specific payment as paid in Firestore.
    func markAsPaid(payment: ScheduledPayment) {
        guard let userId = Auth.auth().currentUser?.uid, let paymentId = payment.id else {
            errorMessage = "Cannot update payment: Missing user or payment ID."
            return
        }
        
        let paymentRef = db.collection("users/\(userId)/scheduled_payments").document(paymentId)
        
        paymentRef.updateData([
            "paid": true,
            "paymentDate": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                // In a real app, you might want to show an alert to the user here.
                print("Error marking payment as paid: \(error.localizedDescription)")
                self.errorMessage = "Failed to update payment. Please try again."
            } else {
                print("Payment \(paymentId) marked as paid.")
            }
        }
    }
    
    /// A helper function to group payments into sections based on their due date.
    func groupPayments(_ payments: [ScheduledPayment]) -> [String: [ScheduledPayment]] {
        let calendar = Calendar.current
        let now = Date()
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: now)!

        // Using a dictionary to group payments. `Dictionary(grouping:by:)` is perfect for this.
        let grouped = Dictionary(grouping: payments) { payment -> String in
            let dueDate = payment.dueDate.dateValue()
            if calendar.isDateInToday(dueDate) || calendar.isDateInTomorrow(dueDate) {
                return "This Week"
            } else if dueDate < endOfWeek {
                return "This Week"
            } else if calendar.isDate(dueDate, equalTo: now, toGranularity: .month) {
                return "Later This Month"
            } else {
                // For future months, use a format like "July 2025"
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: dueDate)
            }
        }
        
        self.groupedPayments = grouped
        return grouped
    }
}
