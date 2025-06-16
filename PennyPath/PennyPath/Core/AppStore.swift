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
import FirebaseAuth

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
    @Published var events: [Event] = []
    
    // MARK: - Authentication Properties
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    // MARK: - Firebase Services
    private let db = Firestore.firestore()
    
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
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, firstName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Create user profile in Firestore
        let newUser = User(id: result.user.uid, firstName: firstName, email: email)
        try await createUserProfile(newUser)
        
        await MainActor.run {
            self.currentUser = newUser
            self.user = newUser
            self.isAuthenticated = true
        }
        
        // Load user's data after authentication
        await loadUserData()
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        
        // Load user profile from Firestore
        let userProfile = try await loadUserProfile(userId: result.user.uid)
        
        await MainActor.run {
            self.currentUser = userProfile
            self.user = userProfile
            self.isAuthenticated = true
        }
        
        // Load user's data after authentication
        await loadUserData()
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        user = nil
        isAuthenticated = false
        // Clear all data
        accounts = []
        transactions = []
        categories = []
        budgets = []
        bnplPlans = []
        flexibleArrangements = []
        transfers = []
        events = []
    }
    
    // MARK: - Firestore Methods
    
    private func createUserProfile(_ user: User) async throws {
        try await db.collection("users").document(user.id).setData(user.toFirestoreData())
    }
    
    private func loadUserProfile(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let user = User(from: document) else {
            throw NSError(domain: "AppStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load user profile"])
        }
        return user
    }
    
    private func loadUserData() async {
        guard let currentUser = currentUser else { return }
        
        // For now, load mock data
        // TODO: Replace with actual Firestore loading
        await MainActor.run {
            loadMockData(for: currentUser.id)
        }
    }
    
    // MARK: - Rules Testing Method
    
    func testFirestoreRules() async {
        print("🧪 Testing Firestore rules from iOS app...")
        
        // Test 1: Try to access data without authentication
        if currentUser == nil {
            do {
                let _ = try await db.collection("users").document("test").getDocument()
                print("❌ ERROR: Unauthenticated access succeeded!")
            } catch {
                print("✅ PASS: Unauthenticated access blocked - \(error.localizedDescription)")
            }
        }
        
        // Test 2: Try to access own data (if authenticated)
        if let user = currentUser {
            do {
                let document = try await db.collection("users").document(user.id).getDocument()
                print("✅ PASS: User can access own data - exists: \(document.exists)")
            } catch {
                print("❌ FAIL: User can't access own data - \(error.localizedDescription)")
            }
            
            // Test 3: Try to access someone else's data
            do {
                let _ = try await db.collection("users").document("different-user-id").getDocument()
                print("❌ ERROR: User accessed another user's data!")
            } catch {
                print("✅ PASS: User can't access other user's data - \(error.localizedDescription)")
            }
        }
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
        // Check if user is already authenticated
        if let currentUser = Auth.auth().currentUser {
            self.currentUser = User(id: currentUser.uid, firstName: "", email: currentUser.email ?? "")
            self.user = self.currentUser
            self.isAuthenticated = true
            Task {
                await loadUserData()
            }
        } else {
            loadMockData(for: "mock-user-id")
        }
    }
    
    // MARK: - Mock Data Loading
    
    private func loadMockData(for userId: String) {
        let mockData = MockDataFactory.createMockData(for: userId)
        
        self.user = mockData.user
        self.accounts = mockData.accounts
        self.transactions = mockData.transactions
        self.categories = mockData.categories
        self.budgets = mockData.budgets
        self.bnplPlans = mockData.bnplPlans
        self.flexibleArrangements = mockData.flexibleArrangements
        self.transfers = mockData.transfers
        self.events = mockData.events
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
