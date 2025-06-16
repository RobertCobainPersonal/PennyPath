//
//  Components.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

// MARK: - Net Worth Display Component
struct NetWorthCard: View {
    let netWorth: Double
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Net Worth")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                }
                
                Text(netWorth.formattedAsCurrencyCompact)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(netWorth >= 0 ? .primary : .red)
                
                HStack {
                    Image(systemName: netWorth >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(netWorth >= 0 ? .green : .red)
                        .font(.caption)
                    
                    Text("Total across all accounts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}






