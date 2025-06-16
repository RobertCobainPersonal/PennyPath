//
//  UpcomingPaymentRow.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

// MARK: - Upcoming Payment Row Component
struct UpcomingPaymentRow: View {
    let transaction: Transaction
    @EnvironmentObject var appStore: AppStore
    
    private var account: Account? {
        appStore.accounts.first { $0.id == transaction.accountId }
    }
    
    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: transaction.date).day ?? 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Payment type icon
            Image(systemName: account?.type.icon ?? "dollarsign.circle")
                .foregroundColor(.blue)
                .font(.title2)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack {
                    Text(account?.name ?? "Unknown Account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if daysUntilDue == 0 {
                        Text("• Due today")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if daysUntilDue == 1 {
                        Text("• Due tomorrow")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("• Due in \(daysUntilDue) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(abs(transaction.amount).formattedAsCurrency)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}
