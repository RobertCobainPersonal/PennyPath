//
//  AccountsListViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//


import Foundation
import Combine

/// ViewModel for Accounts List screen
/// Manages account grouping and filtering logic
class AccountsListViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let appStore: AppStore
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var accountGroups: [AccountGroup] = []
    @Published var totalBalance: Double = 0.0
    @Published var totalAssets: Double = 0.0
    @Published var totalLiabilities: Double = 0.0
    
    // MARK: - Initialization
    init(appStore: AppStore) {
        self.appStore = appStore
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    /// Bind to AppStore changes using Combine
    private func setupBindings() {
        // Listen to account changes and group them
        appStore.$accounts
            .map { [weak self] accounts in
                self?.groupAccounts(accounts) ?? []
            }
            .assign(to: &$accountGroups)
        
        // Calculate total balance
        appStore.$accounts
            .map { accounts in
                accounts.reduce(0) { $0 + $1.balance }
            }
            .assign(to: &$totalBalance)
        
        // Calculate total assets (positive balances)
        appStore.$accounts
            .map { accounts in
                accounts.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance }
            }
            .assign(to: &$totalAssets)
        
        // Calculate total liabilities (negative balances)
        appStore.$accounts
            .map { accounts in
                accounts.filter { $0.balance < 0 }.reduce(0) { $0 + abs($1.balance) }
            }
            .assign(to: &$totalLiabilities)
    }
    
    /// Group accounts by type for organized display
    private func groupAccounts(_ accounts: [Account]) -> [AccountGroup] {
        // Define the order of account groups
        let groupOrder: [(AccountGroupType, [AccountType])] = [
            (.traditional, [.current, .savings, .investment]),
            (.credit, [.credit, .loan]),
            (.modernCredit, [.bnpl, .familyFriend, .debtCollection]),
            (.other, [.prepaid])
        ]
        
        var groups: [AccountGroup] = []
        
        for (groupType, accountTypes) in groupOrder {
            let groupAccounts = accounts.filter { accountTypes.contains($0.type) }
            
            if !groupAccounts.isEmpty {
                let sortedAccounts = groupAccounts.sorted { account1, account2 in
                    // Sort by balance (highest first for assets, lowest first for liabilities)
                    if account1.balance >= 0 && account2.balance >= 0 {
                        return account1.balance > account2.balance
                    } else if account1.balance < 0 && account2.balance < 0 {
                        return account1.balance > account2.balance // Less negative first
                    } else {
                        return account1.balance > account2.balance
                    }
                }
                
                groups.append(AccountGroup(
                    type: groupType,
                    accounts: sortedAccounts
                ))
            }
        }
        
        return groups
    }
}

// MARK: - Helper Models

/// Represents a group of accounts for organized display
struct AccountGroup: Identifiable {
    let id = UUID()
    let type: AccountGroupType
    let accounts: [Account]
    
    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    var accountCount: Int {
        accounts.count
    }
}

/// Types of account groups for organization
enum AccountGroupType: String, CaseIterable {
    case traditional = "traditional"
    case credit = "credit"
    case modernCredit = "modern_credit"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .traditional: return "Banking & Savings"
        case .credit: return "Credit & Loans"
        case .modernCredit: return "Modern Credit"
        case .other: return "Other Accounts"
        }
    }
    
    var icon: String {
        switch self {
        case .traditional: return "building.columns"
        case .credit: return "creditcard"
        case .modernCredit: return "clock.badge"
        case .other: return "ellipsis.circle"
        }
    }
    
    var description: String {
        switch self {
        case .traditional: return "Current accounts, savings, and investments"
        case .credit: return "Credit cards, loans, and mortgages"
        case .modernCredit: return "BNPL, family loans, and debt collection"
        case .other: return "Prepaid cards and miscellaneous accounts"
        }
    }
}
