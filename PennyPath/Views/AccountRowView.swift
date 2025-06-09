//
//  AccountRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

import SwiftUI

// A new subview for displaying a single account row, for better organization.
struct AccountRowView: View {
    let account: Account

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: account.icon.name)
                .font(.title2)
                .foregroundStyle(account.icon.color)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(account.name)
                    .fontWeight(.semibold)
                Text(account.institution)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(account.currentBalance, format: .currency(code: account.currency))
                .fontWeight(.medium)
                .foregroundStyle(account.currentBalance < 0 ? .red : .primary)
        }
        .padding(.vertical, 6)
    }
}
