//
//  AccountDetailViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for Account Detail screen
/// Manages account-specific data and transaction filtering
class AccountDetailViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let appStore: AppStore
    private let accountId: String
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var account: Account?
    @Published var transactions: [Transaction] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var upcomingTransactions: [Transaction] = []
    @Published var currentMonthSpending: Double = 0.0
    @Published var currentMonthIncome: Double = 0.0
    @Published var transactionCount: Int = 0
    @Published var outstandingBNPLPlans: Int = 0
    @Published var nextBNPLPayment: Transaction?
    
    // MARK: - Initialization
    init(appStore: AppStore, accountId: String) {
        self.appStore = appStore
        self.accountId = accountId
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    /// Bind to AppStore changes using Combine
    private func setupBindings() {
        // Find and track the specific account
        appStore.$accounts
            .map { [weak self] accounts in
                accounts.first { $0.id == self?.accountId }
            }
            .assign(to: &$account)
        
        // Filter transactions for this account
        appStore.$transactions
            .map { [weak self] transactions in
                transactions.filter { $0.accountId == self?.accountId }
            }
            .assign(to: &$transactions)
        
        // Calculate recent transactions (last 10, non-scheduled)
        $transactions
            .map { transactions in
                transactions
                    .filter { !$0.isScheduled }
                    .sorted { $0.date > $1.date }
                    .prefix(10)
                    .map { $0 }
            }
            .assign(to: &$recentTransactions)
        
        // Calculate upcoming transactions (next 30 days, scheduled)
        $transactions
            .map { transactions in
                let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
                return transactions
                    .filter { $0.isScheduled && $0.date <= thirtyDaysFromNow }
                    .sorted { $0.date < $1.date }
                    .prefix(5)
                    .map { $0 }
            }
            .assign(to: &$upcomingTransactions)
        
        // Calculate current month spending (negative amounts only)
        $transactions
            .map { [weak self] transactions in
                self?.calculateCurrentMonthSpending(from: transactions) ?? 0.0
            }
            .assign(to: &$currentMonthSpending)
        
        // Calculate current month income (positive amounts only)
        $transactions
            .map { [weak self] transactions in
                self?.calculateCurrentMonthIncome(from: transactions) ?? 0.0
            }
            .assign(to: &$currentMonthIncome)
        
        // Track total transaction count
        $transactions
            .map { transactions in
                transactions.filter { !$0.isScheduled }.count
            }
            .assign(to: &$transactionCount)
        
        // Calculate outstanding BNPL plans (count unique bnplPlanId values)
        $transactions
            .map { transactions in
                let bnplTransactions = transactions.filter { $0.bnplPlanId != nil && $0.isScheduled }
                return Set(bnplTransactions.compactMap { $0.bnplPlanId }).count
            }
            .assign(to: &$outstandingBNPLPlans)
        
        // Find next BNPL payment
        $transactions
            .map { transactions in
                transactions
                    .filter { $0.bnplPlanId != nil && $0.isScheduled && $0.date >= Date() }
                    .sorted { $0.date < $1.date }
                    .first
            }
            .assign(to: &$nextBNPLPayment)
    }
    
    /// Calculate spending for current month (negative amounts)
    private func calculateCurrentMonthSpending(from transactions: [Transaction]) -> Double {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return transactions
            .filter { !$0.isScheduled && $0.amount < 0 && $0.date >= startOfMonth }
            .reduce(0) { $0 + abs($1.amount) }
    }
    
    /// Calculate income for current month (positive amounts)
    private func calculateCurrentMonthIncome(from transactions: [Transaction]) -> Double {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return transactions
            .filter { !$0.isScheduled && $0.amount > 0 && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Helper Properties
    
    /// Check if this account can receive transfers (positive balance accounts)
    var canReceiveTransfers: Bool {
        guard let account = account else { return false }
        return account.type.canHavePositiveBalance
    }
    
    /// Check if this account can send transfers (has positive balance)
    var canSendTransfers: Bool {
        guard let account = account else { return false }
        return account.balance > 0
    }
    
    /// Check if this account supports scheduled payments
    var supportsScheduledPayments: Bool {
        guard let account = account else { return false }
        return account.type.supportsScheduledPayments
    }
    
    /// Get account-specific action suggestions
    var suggestedActions: [AccountAction] {
        guard let currentAccount = account else { return [] }
        
        var actions: [AccountAction] = []
        
        // Always allow adding transactions
        actions.append(.addTransaction)
        
        // Transfer actions based on account type and balance
        if currentAccount.balance > 0 {
            actions.append(.transferOut)
        }
        if currentAccount.type.canHavePositiveBalance {
            actions.append(.transferIn)
        }
        
        // Payment scheduling for credit accounts
        if currentAccount.type.supportsScheduledPayments {
            actions.append(.schedulePayment)
        }
        
        // Account management
        actions.append(.editAccount)
        
        return actions
    }
}

// MARK: - Helper Models

/// Account-specific actions available to users
enum AccountAction: String, CaseIterable, Identifiable {
    case addTransaction = "add_transaction"
    case transferIn = "transfer_in"
    case transferOut = "transfer_out"
    case schedulePayment = "schedule_payment"
    case editAccount = "edit_account"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .addTransaction: return "Add Transaction"
        case .transferIn: return "Transfer In"
        case .transferOut: return "Transfer Out"
        case .schedulePayment: return "Schedule Payment"
        case .editAccount: return "Edit Account"
        }
    }
    
    var icon: String {
        switch self {
        case .addTransaction: return "plus.circle.fill"
        case .transferIn: return "arrow.down.circle.fill"
        case .transferOut: return "arrow.up.circle.fill"
        case .schedulePayment: return "calendar.badge.plus"
        case .editAccount: return "pencil.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .addTransaction: return .blue
        case .transferIn: return .green
        case .transferOut: return .orange
        case .schedulePayment: return .purple
        case .editAccount: return .gray
        }
    }
}
