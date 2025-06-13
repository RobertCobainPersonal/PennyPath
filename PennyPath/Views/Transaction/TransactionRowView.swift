//
//  TransactionRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let category: Category? // UPDATED: Pass in the whole category object
    let currencyCode: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description.isEmpty ? "Transaction" : transaction.description)
                    .fontWeight(.semibold)
                
                HStack {
                    if transaction.isBNPL {
                        Image(systemName: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.cyan)
                    }
                    // UPDATED: Use the category name, or "Uncategorized" if nil
                    Text(category?.name ?? "Uncategorized")
                }
                .font(.caption)
                .foregroundColor(.secondary)

            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.amount, format: .currency(code: currencyCode))
                    .fontWeight(.medium)
                    .foregroundColor(transaction.amount >= 0 ? .primary : .red)
                Text(transaction.date.dateValue(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Preview will also need to be updated slightly
struct TransactionRowView_Previews: PreviewProvider {
    static var previews: some View {
        let mockTransaction = Transaction(
            accountId: "123",
            amount: -49.99,
            date: .init(date: Date()),
            description: "New T-Shirt",
            categoryId: "abc"
        )
        
        let mockCategory = Category(id: "abc", name: "Shopping", iconName: "cart.fill", colorHex: "#FFFFFF")
        
        TransactionRowView(transaction: mockTransaction, category: mockCategory, currencyCode: "GBP")
            .padding()
    }
}
