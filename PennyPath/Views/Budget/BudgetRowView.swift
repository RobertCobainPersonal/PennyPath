//
//  BudgetRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//


//
//  BudgetRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 14/06/2025.
//

import SwiftUI

struct BudgetRowView: View {
    let budgetProgress: BudgetProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let category = budgetProgress.category {
                    Image(systemName: category.iconName)
                        .foregroundColor(category.color)
                    Text(category.name)
                        .fontWeight(.bold)
                } else {
                    Text("Uncategorized Budget")
                        .fontWeight(.bold)
                }
                Spacer()
                Text(budgetProgress.spentAmount, format: .currency(code: "GBP"))
                    .fontWeight(.semibold)
                Text("/")
                    .foregroundColor(.secondary)
                Text(budgetProgress.budget.amount, format: .currency(code: "GBP"))
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: budgetProgress.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: budgetProgress.category?.color ?? .accentColor))

            HStack {
                let remaining = budgetProgress.budget.amount - budgetProgress.spentAmount
                if remaining >= 0 {
                    Text(remaining, format: .currency(code: "GBP"))
                    Text("left")
                        .foregroundColor(.secondary)
                } else {
                    Text(abs(remaining), format: .currency(code: "GBP"))
                    Text("overspent")
                        .foregroundColor(.red)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 8)
    }
}