//
//  AppStore.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//


import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

/// Central state manager for PennyPath app
/// Acts as single source of truth for all app data
class AppStore: ObservableObject {
    
    // MARK: - Published Properties
    @Published var user: User?
    @Published var accounts: [Account] = []
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var budgets: [Budget] = []
    @Published var bnplPlans: [BNPLPlan] = []
    @Published var flexibleArrangements: [FlexibleArrangement] = []
    @Published var transfers: [Transfer] = []
    
    // MARK: - Computed Properties
    
    /// Calculate total net worth across all accounts
    var netWorth: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    /// Get upcoming scheduled transactions (next 30 days)
    var upcomingTransactions: [Transaction] {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return transactions
            .filter { $0.isScheduled && $0.date <= thirtyDaysFromNow }
            .sorted { $0.date < $1.date }
    }
    
    /// Calculate total spending for current month
    var currentMonthSpending: Double {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return transactions
            .filter { !$0.isScheduled && $0.amount < 0 && $0.date >= startOfMonth }
            .reduce(0) { $0 + abs($1.amount) }
    }
    
    // MARK: - Account Management Methods
    
    /// Delete an account and all associated data
    /// This is a cascade delete that removes all related transactions, transfers, etc.
    /// CRITICAL: Also removes transfer transactions from other accounts to prevent orphaning
    func deleteAccount(_ account: Account) {
        // IMPORTANT: Order matters for data integrity
        
        // 1. Find all transfers involving this account (before deletion)
        let relatedTransfers = transfers.filter { $0.fromAccountId == account.id || $0.toAccountId == account.id }
        
        // 2. Delete transfer-related transactions from ALL accounts (not just the one being deleted)
        // This prevents orphaned transactions in other accounts
        for transfer in relatedTransfers {
            // Remove the corresponding transactions in both accounts using robust matching
            transactions.removeAll { transaction in
                // Match by account, amount, and date (within same day) for transfer transactions
                let sameDate = Calendar.current.isDate(transaction.date, inSameDayAs: transfer.date)
                
                // Check if this is the "from" side of the transfer
                let isFromTransaction = (transaction.accountId == transfer.fromAccountId &&
                                       transaction.amount == -transfer.amount &&
                                       sameDate &&
                                       (transaction.description.lowercased().contains("transfer") ||
                                        transaction.categoryId == nil))
                
                // Check if this is the "to" side of the transfer
                let isToTransaction = (transaction.accountId == transfer.toAccountId &&
                                     transaction.amount == transfer.amount &&
                                     sameDate &&
                                     (transaction.description.lowercased().contains("transfer") ||
                                      transaction.description.lowercased().contains("top up") ||
                                      transaction.categoryId == nil))
                
                return isFromTransaction || isToTransaction
            }
        }
        
        // 3. Remove all transfers involving this account
        transfers.removeAll { $0.fromAccountId == account.id || $0.toAccountId == account.id }
        
        // 4. Remove all remaining transactions for this account (non-transfer transactions)
        transactions.removeAll { $0.accountId == account.id }
        
        // 5. Remove all BNPL plans for this account
        bnplPlans.removeAll { $0.accountId == account.id }
        
        // 6. Remove all flexible arrangements for this account
        flexibleArrangements.removeAll { $0.accountId == account.id }
        
        // 7. Finally, remove the account itself
        accounts.removeAll { $0.id == account.id }
        
        // TODO: When Firebase is implemented, this should be a batch operation
    }
    
    /// Update an existing account
    func updateAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        }
        // TODO: When Firebase is implemented, update the document
    }
    
    /// Get deletion impact for an account (for warning dialog)
    /// Shows what data will be deleted and which other accounts will be affected
    func getDeletionImpact(for account: Account) -> AccountDeletionImpact {
        let relatedTransactions = transactions.filter { $0.accountId == account.id }
        let relatedTransfers = transfers.filter { $0.fromAccountId == account.id || $0.toAccountId == account.id }
        let relatedBNPLPlans = bnplPlans.filter { $0.accountId == account.id }
        let relatedFlexibleArrangements = flexibleArrangements.filter { $0.accountId == account.id }
        
        // Find other accounts affected by transfers
        var affectedAccountIds: Set<String> = []
        for transfer in relatedTransfers {
            if transfer.fromAccountId == account.id {
                affectedAccountIds.insert(transfer.toAccountId)
            } else {
                affectedAccountIds.insert(transfer.fromAccountId)
            }
        }
        
        let affectedAccounts = accounts.filter { affectedAccountIds.contains($0.id) }
        
        return AccountDeletionImpact(
            account: account,
            transactionCount: relatedTransactions.count,
            transferCount: relatedTransfers.count,
            bnplPlanCount: relatedBNPLPlans.count,
            flexibleArrangementCount: relatedFlexibleArrangements.count,
            affectedAccounts: affectedAccounts,
            totalImpactedItems: relatedTransactions.count + relatedTransfers.count + relatedBNPLPlans.count + relatedFlexibleArrangements.count
        )
    }
    
    // MARK: - Initialization
    init() {
        setupMockData()
    }
    
    // MARK: - Mock Data Setup
    private func setupMockData() {
        // We'll populate this with mock data shortly
        loadMockData()
    }
    
    private func loadMockData() {
        // Mock User
        user = User(id: "mock-user-id", firstName: "Alex", email: "alex@example.com")
        
        // Mock Categories - UK focused
        let foodCategory = Category(id: "cat-food", userId: "mock-user-id", name: "Food & Dining", color: "#FF6B6B", icon: "fork.knife")
        let transportCategory = Category(id: "cat-transport", userId: "mock-user-id", name: "Transport", color: "#4ECDC4", icon: "car.fill")
        let entertainmentCategory = Category(id: "cat-entertainment", userId: "mock-user-id", name: "Entertainment", color: "#45B7D1", icon: "tv")
        let utilitiesCategory = Category(id: "cat-utilities", userId: "mock-user-id", name: "Bills & Utilities", color: "#96CEB4", icon: "bolt.fill")
        let shoppingCategory = Category(id: "cat-shopping", userId: "mock-user-id", name: "Shopping", color: "#FFEAA7", icon: "bag.fill")
        let salaryCategory = Category(id: "cat-salary", userId: "mock-user-id", name: "Salary", color: "#6C5CE7", icon: "dollarsign.circle.fill")
        
        categories = [foodCategory, transportCategory, entertainmentCategory, utilitiesCategory, shoppingCategory, salaryCategory]
        
        // Mock Accounts - UK banks including BNPL, flexible arrangements, and prepaid with enhanced data
        let currentAccount = Account(id: "acc-current", userId: "mock-user-id", name: "Barclays Current Account", type: .current, balance: 2850.75)
        let savingsAccount = Account(id: "acc-savings", userId: "mock-user-id", name: "HSBC Instant Saver", type: .savings, balance: 8420.00)
        let creditAccount = Account(id: "acc-credit", userId: "mock-user-id", name: "Santander Cashback Credit Card", type: .credit, balance: -892.45, creditLimit: 3000.00)
        let loanAccount = Account(id: "acc-loan", userId: "mock-user-id", name: "Lloyds Car Finance", type: .loan, balance: -12750.00, originalLoanAmount: 18000.00, loanTermMonths: 48, loanStartDate: Calendar.current.date(byAdding: .month, value: -18, to: Date()), interestRate: 5.9, monthlyPayment: 425.50)
        let klarnaAccount = Account(id: "acc-klarna", userId: "mock-user-id", name: "Klarna", type: .bnpl, balance: -124.97, bnplProvider: "Klarna")
        let clearpayAccount = Account(id: "acc-clearpay", userId: "mock-user-id", name: "Clearpay", type: .bnpl, balance: -79.98, bnplProvider: "Clearpay")
        let familyAccount = Account(id: "acc-family", userId: "mock-user-id", name: "Loan from Parents", type: .familyFriend, balance: -5000.00, originalLoanAmount: 8000.00, loanStartDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()))
        let debtCollectionAccount = Account(id: "acc-debt", userId: "mock-user-id", name: "Lowell Debt Collection", type: .debtCollection, balance: -847.32, originalLoanAmount: 1200.00)
        let golfClubAccount = Account(id: "acc-golf", userId: "mock-user-id", name: "Golf Club Bar Card", type: .prepaid, balance: 47.50)
        
        accounts = [currentAccount, savingsAccount, creditAccount, loanAccount, klarnaAccount, clearpayAccount, familyAccount, debtCollectionAccount, golfClubAccount]
        
        // Mock Transactions - UK focused
        let calendar = Calendar.current
        let today = Date()
        
        transactions = [
            // Past transactions - UK businesses and terminology
            Transaction(id: "txn-1", userId: "mock-user-id", accountId: "acc-current",
                       categoryId: "cat-food", amount: -8.45,
                       description: "Pret A Manger", date: calendar.date(byAdding: .day, value: -1, to: today)!),
            
            Transaction(id: "txn-2", userId: "mock-user-id", accountId: "acc-current",
                       categoryId: "cat-shopping", amount: -42.99,
                       description: "Tesco Groceries", date: calendar.date(byAdding: .day, value: -2, to: today)!),
            
            Transaction(id: "txn-3", userId: "mock-user-id", accountId: "acc-current",
                       categoryId: "cat-transport", amount: -65.40,
                       description: "Shell Petrol Station", date: calendar.date(byAdding: .day, value: -3, to: today)!),
            
            Transaction(id: "txn-4", userId: "mock-user-id", accountId: "acc-current",
                       categoryId: "cat-entertainment", amount: -12.50,
                       description: "Vue Cinema", date: calendar.date(byAdding: .day, value: -4, to: today)!),
            
            Transaction(id: "txn-5", userId: "mock-user-id", accountId: "acc-current",
                       categoryId: "cat-salary", amount: 2800.00,
                       description: "Monthly Salary", date: calendar.date(byAdding: .day, value: -5, to: today)!),
            
            // Upcoming scheduled transactions
            Transaction(id: "txn-6", userId: "mock-user-id", accountId: "acc-loan",
                       categoryId: nil, amount: -320.50,
                       description: "Car Finance Payment", date: calendar.date(byAdding: .day, value: 3, to: today)!,
                       isScheduled: true, recurrence: .monthly),
            
            Transaction(id: "txn-7", userId: "mock-user-id", accountId: "acc-current",
                       categoryId: "cat-utilities", amount: -89.00,
                       description: "British Gas Bill", date: calendar.date(byAdding: .day, value: 7, to: today)!,
                       isScheduled: true, recurrence: .monthly),
            
            Transaction(id: "txn-8", userId: "mock-user-id", accountId: "acc-current",
                       categoryId: "cat-utilities", amount: -45.00,
                       description: "BT Broadband", date: calendar.date(byAdding: .day, value: 12, to: today)!,
                       isScheduled: true, recurrence: .monthly),
            
            Transaction(id: "txn-9", userId: "mock-user-id", accountId: "acc-credit",
                       categoryId: nil, amount: -75.00,
                       description: "Credit Card Payment", date: calendar.date(byAdding: .day, value: 15, to: today)!,
                       isScheduled: true, recurrence: .monthly),
            
            Transaction(id: "txn-10", userId: "mock-user-id", accountId: "acc-current",
                       categoryId: "cat-utilities", amount: -125.00,
                       description: "Council Tax", date: calendar.date(byAdding: .day, value: 20, to: today)!,
                       isScheduled: true, recurrence: .monthly)
        ]
        
        // Add prepaid account (golf club) transactions
        let golfClubTransactions = [
            // Top up transfer (money leaving current account)
            Transaction(id: "txn-current-golf", userId: "mock-user-id", accountId: "acc-current",
                       categoryId: nil, amount: -100.00,
                       description: "Transfer to Golf Club Bar Card",
                       date: calendar.date(byAdding: .day, value: -10, to: today)!),
            
            // Top up transfer (money arriving in golf club account)
            Transaction(id: "txn-golf-topup", userId: "mock-user-id", accountId: "acc-golf",
                       categoryId: nil, amount: 100.00,
                       description: "Top up from Current Account",
                       date: calendar.date(byAdding: .day, value: -10, to: today)!),
            
            // Golf club spending
            Transaction(id: "txn-golf-1", userId: "mock-user-id", accountId: "acc-golf",
                       categoryId: "cat-entertainment", amount: -15.50,
                       description: "Drinks after round",
                       date: calendar.date(byAdding: .day, value: -8, to: today)!),
            
            Transaction(id: "txn-golf-2", userId: "mock-user-id", accountId: "acc-golf",
                       categoryId: "cat-food", amount: -18.00,
                       description: "Club sandwich & coffee",
                       date: calendar.date(byAdding: .day, value: -5, to: today)!),
            
            Transaction(id: "txn-golf-3", userId: "mock-user-id", accountId: "acc-golf",
                       categoryId: "cat-entertainment", amount: -12.50,
                       description: "Post-game pints",
                       date: calendar.date(byAdding: .day, value: -2, to: today)!),
            
            Transaction(id: "txn-golf-4", userId: "mock-user-id", accountId: "acc-golf",
                       categoryId: "cat-food", amount: -6.50,
                       description: "Coffee & biscuits",
                       date: today)
        ]
        
        transactions.append(contentsOf: golfClubTransactions)
        
        // Add flexible arrangement transactions
        let flexibleTransactions = [
            // Family loan payments (irregular amounts, showing flexibility)
            Transaction(id: "txn-family-1", userId: "mock-user-id", accountId: "acc-family",
                       categoryId: nil, amount: -500.00,
                       description: "Payment to Parents",
                       date: calendar.date(byAdding: .month, value: -5, to: today)!),
            
            Transaction(id: "txn-family-2", userId: "mock-user-id", accountId: "acc-family",
                       categoryId: nil, amount: -1000.00,
                       description: "Payment to Parents",
                       date: calendar.date(byAdding: .month, value: -3, to: today)!),
            
            Transaction(id: "txn-family-3", userId: "mock-user-id", accountId: "acc-family",
                       categoryId: nil, amount: -750.00,
                       description: "Payment to Parents",
                       date: calendar.date(byAdding: .month, value: -1, to: today)!),
            
            Transaction(id: "txn-family-4", userId: "mock-user-id", accountId: "acc-family",
                       categoryId: nil, amount: -750.00,
                       description: "Payment to Parents",
                       date: today),
            
            // Debt collection payments (more regular, smaller amounts)
            Transaction(id: "txn-debt-1", userId: "mock-user-id", accountId: "acc-debt",
                       categoryId: nil, amount: -50.00,
                       description: "Lowell Group Payment",
                       date: calendar.date(byAdding: .month, value: -3, to: today)!),
            
            Transaction(id: "txn-debt-2", userId: "mock-user-id", accountId: "acc-debt",
                       categoryId: nil, amount: -75.00,
                       description: "Lowell Group Payment",
                       date: calendar.date(byAdding: .month, value: -2, to: today)!),
            
            Transaction(id: "txn-debt-3", userId: "mock-user-id", accountId: "acc-debt",
                       categoryId: nil, amount: -50.00,
                       description: "Lowell Group Payment",
                       date: calendar.date(byAdding: .month, value: -1, to: today)!),
            
            Transaction(id: "txn-debt-4", userId: "mock-user-id", accountId: "acc-debt",
                       categoryId: nil, amount: -25.00,
                       description: "Lowell Group Payment",
                       date: calendar.date(byAdding: .day, value: -15, to: today)!),
            
            // Upcoming debt collection payment (scheduled)
            Transaction(id: "txn-debt-5", userId: "mock-user-id", accountId: "acc-debt",
                       categoryId: nil, amount: -50.00,
                       description: "Lowell Group Payment",
                       date: calendar.date(byAdding: .day, value: 18, to: today)!, isScheduled: true, recurrence: .monthly)
        ]
        
        transactions.append(contentsOf: flexibleTransactions)
        
        // Mock BNPL Plans - user-defined providers
        let klarnaPlan = BNPLPlan(
            id: "bnpl-klarna-1",
            userId: "mock-user-id",
            accountId: "acc-klarna",
            providerName: "Klarna",
            totalAmount: 249.95,
            numberOfInstallments: 4,
            frequency: .biweekly,
            startDate: calendar.date(byAdding: .day, value: -14, to: today)!,
            description: "ASOS Fashion Purchase"
        )
        
        let clearpayPlan = BNPLPlan(
            id: "bnpl-clearpay-1",
            userId: "mock-user-id",
            accountId: "acc-clearpay",
            providerName: "Clearpay",
            totalAmount: 159.99,
            numberOfInstallments: 4,
            frequency: .biweekly,
            startDate: calendar.date(byAdding: .day, value: -7, to: today)!,
            description: "John Lewis Home Goods"
        )
        
        bnplPlans = [klarnaPlan, clearpayPlan]
        
        // Mock Flexible Arrangements
        let familyLoan = FlexibleArrangement(
            id: "flex-family-1",
            userId: "mock-user-id",
            accountId: "acc-family",
            type: .familyFriendLoan,
            originalAmount: 8000.00,
            description: "House deposit help",
            startDate: calendar.date(byAdding: .month, value: -6, to: today)!,
            targetCompletionDate: calendar.date(byAdding: .year, value: 2, to: today),
            suggestedPayment: 200.00,
            notes: "No rush, pay when you can. Family comes first! 💙",
            relationshipType: .parent,
            contactName: "Mum & Dad",
            contactPhone: "07123 456789"
        )
        
        let debtCollection = FlexibleArrangement(
            id: "flex-debt-1",
            userId: "mock-user-id",
            accountId: "acc-debt",
            type: .debtCollection,
            originalAmount: 1200.00,
            description: "Old Argos credit card debt",
            startDate: calendar.date(byAdding: .month, value: -3, to: today)!,
            minimumPayment: 25.00,
            suggestedPayment: 50.00,
            notes: "Making steady progress. Settlement offer available.",
            originalCreditor: "Argos Financial Services",
            collectionAgency: "Lowell Group",
            referenceNumber: "LG/2024/789123",
            settlementAmount: 600.00
        )
        
        flexibleArrangements = [familyLoan, debtCollection]
        
        // Mock Transfers
        let golfClubTopUp = Transfer(
            id: "transfer-golf-1",
            userId: "mock-user-id",
            fromAccountId: "acc-current",
            toAccountId: "acc-golf",
            amount: 100.00,
            description: "Golf Club Bar Card",
            date: calendar.date(byAdding: .day, value: -10, to: today)!,
            transferType: .topUp
        )
        
        transfers = [golfClubTopUp]
        
        // Add BNPL transactions to existing transactions
        let bnplTransactions = [
            // Klarna payments (first payment made, rest scheduled)
            Transaction(id: "txn-klarna-1", userId: "mock-user-id", accountId: "acc-klarna",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-klarna-1", amount: -62.49,
                       description: "ASOS - Payment 1/4",
                       date: calendar.date(byAdding: .day, value: -14, to: today)!),
            
            Transaction(id: "txn-klarna-2", userId: "mock-user-id", accountId: "acc-klarna",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-klarna-1", amount: -62.49,
                       description: "ASOS - Payment 2/4",
                       date: today, isScheduled: true),
            
            Transaction(id: "txn-klarna-3", userId: "mock-user-id", accountId: "acc-klarna",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-klarna-1", amount: -62.49,
                       description: "ASOS - Payment 3/4",
                       date: calendar.date(byAdding: .day, value: 14, to: today)!, isScheduled: true),
            
            Transaction(id: "txn-klarna-4", userId: "mock-user-id", accountId: "acc-klarna",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-klarna-1", amount: -62.48,
                       description: "ASOS - Payment 4/4",
                       date: calendar.date(byAdding: .day, value: 28, to: today)!, isScheduled: true),
            
            // Clearpay payments (first payment made, rest scheduled)
            Transaction(id: "txn-clearpay-1", userId: "mock-user-id", accountId: "acc-clearpay",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-clearpay-1", amount: -40.00,
                       description: "John Lewis - Payment 1/4",
                       date: calendar.date(byAdding: .day, value: -7, to: today)!),
            
            Transaction(id: "txn-clearpay-2", userId: "mock-user-id", accountId: "acc-clearpay",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-clearpay-1", amount: -40.00,
                       description: "John Lewis - Payment 2/4",
                       date: calendar.date(byAdding: .day, value: 7, to: today)!, isScheduled: true),
            
            Transaction(id: "txn-clearpay-3", userId: "mock-user-id", accountId: "acc-clearpay",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-clearpay-1", amount: -39.99,
                       description: "John Lewis - Payment 3/4",
                       date: calendar.date(byAdding: .day, value: 21, to: today)!, isScheduled: true),
            
            Transaction(id: "txn-clearpay-4", userId: "mock-user-id", accountId: "acc-clearpay",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-clearpay-1", amount: -40.00,
                       description: "John Lewis - Payment 4/4",
                       date: calendar.date(byAdding: .day, value: 35, to: today)!, isScheduled: true)
        ]
        
        transactions.append(contentsOf: bnplTransactions)
        
        // Mock Budgets - UK appropriate amounts
        budgets = [
            Budget(id: "budget-food", userId: "mock-user-id", categoryId: "cat-food", amount: 400.00),
            Budget(id: "budget-transport", userId: "mock-user-id", categoryId: "cat-transport", amount: 200.00),
            Budget(id: "budget-entertainment", userId: "mock-user-id", categoryId: "cat-entertainment", amount: 150.00)
        ]
    }
}

// MARK: - Helper Models for Account Management

/// Impact analysis for account deletion with enhanced cross-account warnings
struct AccountDeletionImpact {
    let account: Account
    let transactionCount: Int
    let transferCount: Int
    let bnplPlanCount: Int
    let flexibleArrangementCount: Int
    let affectedAccounts: [Account]
    let totalImpactedItems: Int
    
    var hasImpact: Bool {
        totalImpactedItems > 0 || !affectedAccounts.isEmpty
    }
    
    var impactDescription: String {
        var items: [String] = []
        
        if transactionCount > 0 {
            items.append("\(transactionCount) transaction\(transactionCount == 1 ? "" : "s")")
        }
        if transferCount > 0 {
            items.append("\(transferCount) transfer\(transferCount == 1 ? "" : "s")")
        }
        if bnplPlanCount > 0 {
            items.append("\(bnplPlanCount) BNPL plan\(bnplPlanCount == 1 ? "" : "s")")
        }
        if flexibleArrangementCount > 0 {
            items.append("\(flexibleArrangementCount) payment arrangement\(flexibleArrangementCount == 1 ? "" : "s")")
        }
        
        var result = ""
        
        // Describe what will be deleted
        if items.isEmpty {
            result = "No transaction data will be deleted."
        } else if items.count == 1 {
            result = items[0] + " will be permanently deleted."
        } else if items.count == 2 {
            result = items.joined(separator: " and ") + " will be permanently deleted."
        } else {
            let lastItem = items.removeLast()
            result = items.joined(separator: ", ") + ", and " + lastItem + " will be permanently deleted."
        }
        
        // Add affected accounts warning
        if !affectedAccounts.isEmpty {
            let accountNames = affectedAccounts.map { $0.name }
            let affectedText: String
            
            if accountNames.count == 1 {
                affectedText = "\n\nThis will also affect 1 other account: \(accountNames[0]). Transfer transactions in this account will be removed."
            } else if accountNames.count == 2 {
                affectedText = "\n\nThis will also affect 2 other accounts: \(accountNames.joined(separator: " and ")). Transfer transactions in these accounts will be removed."
            } else {
                let lastAccount = accountNames.dropLast().joined(separator: ", ")
                affectedText = "\n\nThis will also affect \(accountNames.count) other accounts: \(lastAccount), and \(accountNames.last!). Transfer transactions in these accounts will be removed."
            }
            
            result += affectedText
        }
        
        return result
    }
}
