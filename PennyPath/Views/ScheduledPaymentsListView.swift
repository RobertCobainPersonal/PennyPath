//
//  ScheduledPaymentsListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//


import SwiftUI
import FirebaseFirestore

// MARK: - Main View

struct ScheduledPaymentsListView: View {
    
    @StateObject fileprivate var viewModel = ScheduledPaymentsViewModel()
    
    // Computed property to get sorted keys for the list sections
    private var sortedSectionTitles: [String] {
        let sectionOrder = ["This Week", "Later This Month"]
        
        // Sort the dictionary keys to ensure a consistent order in the UI.
        return viewModel.groupedPayments.keys.sorted { (key1, key2) -> Bool in
            if let index1 = sectionOrder.firstIndex(of: key1), let index2 = sectionOrder.firstIndex(of: key2) {
                return index1 < index2
            }
            if sectionOrder.contains(key1) { return true }
            if sectionOrder.contains(key2) { return false }
            return key1 < key2 // Sort future months alphabetically
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading Payments...")
                } else if viewModel.groupedPayments.isEmpty {
                    ContentUnavailableView(
                        "All Caught Up!",
                        systemImage: "checkmark.circle.fill",
                        description: Text("You have no upcoming scheduled payments.")
                    )
                } else {
                    paymentList
                }
            }
            .navigationTitle("Upcoming Payments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // In the future, this could open a view to add a new recurring payment.
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private var paymentList: some View {
        List {
            // Iterate over the sorted keys to create sections.
            ForEach(sortedSectionTitles, id: \.self) { sectionTitle in
                Section(header: Text(sectionTitle).font(.headline)) {
                    // Iterate over the payments within each group.
                    ForEach(viewModel.groupedPayments[sectionTitle] ?? [], id: \.self) { payment in
                        ScheduledPaymentRowView(
                            payment: payment,
                            sourceAccountName: viewModel.accountNameLookup[payment.sourceAccountId] ?? "Unknown Account",
                            targetAccountName: payment.targetAccountId.flatMap { viewModel.accountNameLookup[$0] }
                        )
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                viewModel.markAsPaid(payment: payment)
                            } label: {
                                Label("Mark as Paid", systemImage: "checkmark.circle.fill")
                            }
                            .tint(.green)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SwiftUI Preview

struct ScheduledPaymentsListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockView = ScheduledPaymentsListView()
        
        // This preview does not fetch from Firestore and uses mock data.
        // We will manually inject the data into the ViewModel.
        let viewModel = mockView.viewModel
        
        let today = Date()
        let mockPayments: [ScheduledPayment] = [
            .init(id: "1", transactionId: "t1", sourceAccountId: "acc1", amount: 25.00, dueDate: Timestamp(date: today), recurrence: .weekly),
            .init(id: "2", transactionId: "t2", sourceAccountId: "acc1", targetAccountId: "acc2", amount: 150.00, dueDate: Timestamp(date: Calendar.current.date(byAdding: .day, value: 3, to: today)!)),
            .init(id: "3", transactionId: "t3", sourceAccountId: "acc2", amount: 9.99, dueDate: Timestamp(date: Calendar.current.date(byAdding: .day, value: 10, to: today)!), recurrence: .monthly),
            .init(id: "4", transactionId: "t4", sourceAccountId: "acc2", amount: 45.50, dueDate: Timestamp(date: Calendar.current.date(byAdding: .month, value: 1, to: today)!))
        ]
        
        let mockAccountLookup = [
            "acc1": "Monzo Current Account",
            "acc2": "Barclaycard"
        ]
        
        viewModel.groupedPayments = viewModel.groupPayments(mockPayments)
        viewModel.accountNameLookup = mockAccountLookup
        viewModel.isLoading = false
        
        return mockView
    }
}
