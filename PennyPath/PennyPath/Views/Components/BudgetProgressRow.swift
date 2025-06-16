//
//  BudgetProgressRow.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

// MARK: - Budget Progress Component
struct BudgetProgressRow: View {
    let budgetItem: BudgetProgressItem
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: budgetItem.categoryIcon)
                        .foregroundColor(Color(hex: budgetItem.categoryColor))
                        .font(.title3)
                    
                    Text(budgetItem.categoryName)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(budgetItem.spentAmount.formattedAsCurrency) / \(budgetItem.budgetAmount.formattedAsCurrency)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if budgetItem.isOverBudget {
                        Text("Over budget")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    } else {
                        Text("\(budgetItem.remainingAmount.formattedAsCurrency) left")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(budgetItem.isOverBudget ? Color.red : Color(hex: budgetItem.categoryColor))
                        .frame(width: geometry.size.width * budgetItem.progressPercentage, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
}
