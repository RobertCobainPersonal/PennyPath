//
//  AccountsListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

struct AccountsListView: View {
    @EnvironmentObject var appStore: AppStore
    @StateObject private var viewModel: AccountsListViewModel
    
    init(appStore: AppStore) {
        self._viewModel = StateObject(wrappedValue: AccountsListViewModel(appStore: appStore))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Financial overview summary
                    overviewSection
                    
                    // Account groups
                    accountGroupsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Add account action
                    }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var overviewSection: some View {
        HStack(spacing: 16) {
            // Assets card
            CardView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        Spacer()
                        
                        Text("Assets")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(viewModel.totalAssets.formattedAsCurrency)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            // Liabilities card
            CardView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        
                        Spacer()
                        
                        Text("Liabilities")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(viewModel.totalLiabilities.formattedAsCurrency)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var accountGroupsSection: some View {
        ForEach(viewModel.accountGroups) { group in
            VStack(alignment: .leading, spacing: 12) {
                // Group header
                groupHeaderView(for: group)
                
                // Accounts in this group
                CardView {
                    VStack(spacing: 0) {
                        ForEach(group.accounts) { account in
                            AccountRowView(account: account)
                            
                            if account.id != group.accounts.last?.id {
                                Divider()
                                    .padding(.leading, 56) // Align with text, not icon
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func groupHeaderView(for group: AccountGroup) -> some View {
        HStack {
            Image(systemName: group.type.icon)
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(group.type.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(group.type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(group.totalBalance.formattedAsCurrency)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(group.totalBalance >= 0 ? .green : .red)
                
                Text("\(group.accountCount) account\(group.accountCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Account Row Component
struct AccountRowView: View {
    let account: Account
    @EnvironmentObject var appStore: AppStore
    
    var body: some View {
        NavigationLink(destination: AccountDetailView(accountId: account.id, appStore: appStore)) {
            HStack(spacing: 12) {
                // Account type icon
                ZStack {
                    Circle()
                        .fill(Color(hex: account.type.color).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: account.type.icon)
                        .font(.headline)
                        .foregroundColor(Color(hex: account.type.color))
                }
                
                // Account info
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(account.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Balance and arrow
                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.balance.formattedAsCurrency)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(account.balance >= 0 ? .primary : .red)
                    
                    HStack(spacing: 4) {
                        // Simple trend indicator (could be enhanced later)
                        Image(systemName: "minus")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("No change")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview Provider
struct AccountsListView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsListView(appStore: AppStore())
            .environmentObject(AppStore())
    }
}

struct AccountRowView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack {
                AccountRowView(account: Account(
                    userId: "test",
                    name: "Barclays Current Account",
                    type: .current,
                    balance: 2850.75
                ))
                .environmentObject(AppStore())
                
                Divider()
                
                AccountRowView(account: Account(
                    userId: "test",
                    name: "Santander Credit Card",
                    type: .credit,
                    balance: -892.45
                ))
                .environmentObject(AppStore())
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
    }
}
