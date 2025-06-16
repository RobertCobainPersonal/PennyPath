//
//  SpendingCard.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

// MARK: - Spending Summary Component
struct SpendingCard: View {
    let currentMonthSpending: Double
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("This Month")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "creditcard")
                        .foregroundColor(.orange)
                }
                
                Text(currentMonthSpending.formattedAsCurrency)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Total spending")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
