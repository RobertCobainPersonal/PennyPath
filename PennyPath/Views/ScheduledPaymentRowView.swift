//
//  ScheduledPaymentRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//


import SwiftUI
import FirebaseFirestore

// MARK: - Row Subview

struct ScheduledPaymentRowView: View {
    let payment: ScheduledPayment
    let sourceAccountName: String
    let targetAccountName: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Display the amount and recurrence icon.
                HStack(spacing: 8) {
                    Text(payment.amount, format: .currency(code: "GBP"))
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if payment.recurrence != .none {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .help("Recurring Payment") // Tooltip for macOS/iPadOS
                    }
                }
                
                // Display the source and optional target accounts.
                HStack {
                    Text(sourceAccountName)
                    if let target = targetAccountName {
                        Image(systemName: "arrow.right")
                        Text(target)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Display the due date.
            Text(payment.dueDate.dateValue(), style: .date)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
}