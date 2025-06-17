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
                
                // Accounts in this group using extracted component
                CardView {
                    VStack(spacing: 0) {
                        ForEach(group.accounts) { account in
                            AccountRowView(
                                account: account,
                                showBalance: true,
                                showTrend: true,
                                showChevron: true,
                                navigationDestination: AnyView(AccountDetailView(accountId: account.id, appStore: appStore))
                            )
                            
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

// MARK: - Preview Provider
struct AccountsListView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsListView(appStore: AppStore())
            .environmentObject(AppStore())
    }
}
