//
//  AccountRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
//  REFACTORED: This view now accepts the calculated balance as a parameter
//  instead of reading it directly from the Account model.
//

import SwiftUI

// A new subview for displaying a single account row, for better organization.
struct AccountRowView: View {
    let account: Account
    let balance: Double // The calculated balance is now passed in.

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
            
            Text(balance, format: .currency(code: account.currency))
                .fontWeight(.medium)
                .foregroundStyle(balance < 0 ? .red : .primary)
        }
        .padding(.vertical, 6)
    }
}

// The preview needs to be updated to pass in a sample balance.
struct AccountRowView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAccount = Account(
            name: "Monzo",
            type: .currentAccount,
            institution: "Monzo Bank",
            anchorBalance: 1234.56,
            anchorDate: .init(date: Date())
        )
        
        AccountRowView(account: mockAccount, balance: 1234.56)
            .padding()
    }
}

