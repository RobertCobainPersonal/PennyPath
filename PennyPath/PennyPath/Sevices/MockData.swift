//
//  MockDataFactory.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import Foundation

/// Factory class for generating realistic mock data for development and testing
class MockDataFactory {
    
    /// Generate complete mock data set for a user
    static func createMockData(for userId: String) -> MockDataSet {
        let calendar = Calendar.current
        let today = Date()
        
        // Mock Categories - Proper income/expense split
        let categories = createMockCategories(for: userId)
        
        // Mock Events - Create first so we can reference them in transactions
        let events = createMockEvents(for: userId, today: today)
        
        // Mock Accounts - UK banks including BNPL, flexible arrangements, and prepaid with enhanced data
        let accounts = createMockAccounts(for: userId)
        
        // Mock Transactions - UK focused with proper income/expense categorization and events
        var transactions = createMockTransactions(for: userId, accounts: accounts, categories: categories, events: events, today: today)
        
        // Add prepaid account (golf club) transactions
        let golfClubTransactions = createGolfClubTransactions(for: userId, events: events, today: today)
        transactions.append(contentsOf: golfClubTransactions)
        
        // Add flexible arrangement transactions
        let flexibleTransactions = createFlexibleArrangementTransactions(for: userId, today: today)
        transactions.append(contentsOf: flexibleTransactions)
        
        // Add BNPL transactions
        let bnplTransactions = createBNPLTransactions(for: userId, today: today)
        transactions.append(contentsOf: bnplTransactions)
        
        // Mock BNPL Plans - user-defined providers
        let bnplPlans = createMockBNPLPlans(for: userId, today: today)
        
        // Mock Flexible Arrangements
        let flexibleArrangements = createMockFlexibleArrangements(for: userId, today: today)
        
        // Mock Transfers
        let transfers = createMockTransfers(for: userId, today: today)
        
        // Mock Budgets - UK appropriate amounts (expense categories only)
        let budgets = createMockBudgets(for: userId, categories: categories)
        
        return MockDataSet(
            user: User(id: userId, firstName: "Alex", email: "alex@example.com"),
            accounts: accounts,
            transactions: transactions,
            categories: categories,
            budgets: budgets,
            bnplPlans: bnplPlans,
            flexibleArrangements: flexibleArrangements,
            transfers: transfers,
            events: events
        )
    }
    
    // MARK: - Private Factory Methods
    
    private static func createMockCategories(for userId: String) -> [Category] {
        return [
            // INCOME CATEGORIES
            Category(id: "cat-salary", userId: userId, name: "Salary", color: "#6C5CE7", icon: "dollarsign.circle.fill", categoryType: .income),
            Category(id: "cat-freelance", userId: userId, name: "Freelance", color: "#00B894", icon: "briefcase.fill", categoryType: .income),
            Category(id: "cat-benefits", userId: userId, name: "Benefits", color: "#0984E3", icon: "hand.raised.fill", categoryType: .income),
            Category(id: "cat-investment", userId: userId, name: "Investment Returns", color: "#00CEC9", icon: "chart.line.uptrend.xyaxis", categoryType: .income),
            Category(id: "cat-rental", userId: userId, name: "Rental Income", color: "#A29BFE", icon: "house.fill", categoryType: .income),
            Category(id: "cat-gifts", userId: userId, name: "Gifts & Windfalls", color: "#FD79A8", icon: "gift.fill", categoryType: .income),
            
            // EXPENSE CATEGORIES
            Category(id: "cat-food", userId: userId, name: "Food & Dining", color: "#FF6B6B", icon: "fork.knife", categoryType: .expense),
            Category(id: "cat-transport", userId: userId, name: "Transport", color: "#4ECDC4", icon: "car.fill", categoryType: .expense),
            Category(id: "cat-entertainment", userId: userId, name: "Entertainment", color: "#45B7D1", icon: "tv", categoryType: .expense),
            Category(id: "cat-utilities", userId: userId, name: "Bills & Utilities", color: "#96CEB4", icon: "bolt.fill", categoryType: .expense),
            Category(id: "cat-shopping", userId: userId, name: "Shopping", color: "#FFEAA7", icon: "bag.fill", categoryType: .expense),
            Category(id: "cat-healthcare", userId: userId, name: "Healthcare & NHS", color: "#FD79A8", icon: "cross.fill", categoryType: .expense),
            Category(id: "cat-subscriptions", userId: userId, name: "Subscriptions", color: "#81ECEC", icon: "rectangle.stack.fill", categoryType: .expense)
        ]
    }
    
    private static func createMockEvents(for userId: String, today: Date) -> [Event] {
        let calendar = Calendar.current
        
        return [
            // Past event (completed)
            Event(
                id: "event-paris",
                userId: userId,
                name: "Weekend in Paris",
                description: "Romantic getaway with partner",
                startDate: calendar.date(byAdding: .day, value: -10, to: today),
                endDate: calendar.date(byAdding: .day, value: -8, to: today),
                color: "#FF6B6B",
                icon: "airplane",
                isActive: false
            ),
            
            // Current/ongoing event
            Event(
                id: "event-kitchen",
                userId: userId,
                name: "Kitchen Renovation",
                description: "Complete kitchen remodel project",
                startDate: calendar.date(byAdding: .month, value: -1, to: today),
                endDate: calendar.date(byAdding: .month, value: 1, to: today),
                color: "#4ECDC4",
                icon: "hammer",
                isActive: true
            ),
            
            // Future event
            Event(
                id: "event-golf",
                userId: userId,
                name: "Golf Trip to Turkey",
                description: "Annual golf holiday with the lads",
                startDate: calendar.date(byAdding: .month, value: 2, to: today),
                endDate: calendar.date(byAdding: .month, value: 2, to: today)?.addingTimeInterval(7 * 24 * 60 * 60),
                color: "#45B7D1",
                icon: "figure.golf",
                isActive: true
            ),
            
            // Another active event - FIXED
            Event(
                id: "event-birthday",
                userId: userId,
                name: "Ashlea's Birthday Trip",
                description: "Birthday celebration weekend",
                startDate: calendar.date(byAdding: .weekOfYear, value: 2, to: today),
                endDate: calendar.date(byAdding: .weekOfYear, value: 2, to: today)?.addingTimeInterval(3 * 24 * 60 * 60),
                color: "#FD79A8",
                icon: "gift",
                isActive: true
            )
        ]
    }
    
    private static func createMockAccounts(for userId: String) -> [Account] {
        return [
            Account(id: "acc-current", userId: userId, name: "Barclays Current Account", type: .current, balance: 2850.75),
            Account(id: "acc-savings", userId: userId, name: "HSBC Instant Saver", type: .savings, balance: 8420.00),
            Account(id: "acc-credit", userId: userId, name: "Santander Cashback Credit Card", type: .credit, balance: -892.45, creditLimit: 3000.00),
            Account(id: "acc-loan", userId: userId, name: "Lloyds Car Finance", type: .loan, balance: -12750.00, originalLoanAmount: 18000.00, loanTermMonths: 48, loanStartDate: Calendar.current.date(byAdding: .month, value: -18, to: Date()), interestRate: 5.9, monthlyPayment: 425.50),
            Account(id: "acc-klarna", userId: userId, name: "Klarna", type: .bnpl, balance: -124.97, bnplProvider: "Klarna"),
            Account(id: "acc-clearpay", userId: userId, name: "Clearpay", type: .bnpl, balance: -79.98, bnplProvider: "Clearpay"),
            Account(id: "acc-family", userId: userId, name: "Loan from Parents", type: .familyFriend, balance: -5000.00, originalLoanAmount: 8000.00, loanStartDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())),
            Account(id: "acc-debt", userId: userId, name: "Lowell Debt Collection", type: .debtCollection, balance: -847.32, originalLoanAmount: 1200.00),
            Account(id: "acc-golf", userId: userId, name: "Golf Club Bar Card", type: .prepaid, balance: 47.50)
        ]
    }
    
    private static func createMockTransactions(for userId: String, accounts: [Account], categories: [Category], events: [Event], today: Date) -> [Transaction] {
        let calendar = Calendar.current
        
        return [
            // EXPENSE TRANSACTIONS - Some tagged to events
            Transaction(id: "txn-1", userId: userId, accountId: "acc-current",
                       categoryId: "cat-food", amount: -8.45,
                       description: "Pret A Manger", date: calendar.date(byAdding: .day, value: -1, to: today)!),
            
            Transaction(id: "txn-2", userId: userId, accountId: "acc-current",
                       categoryId: "cat-shopping", eventId: "event-kitchen", amount: -159.99,
                       description: "B&Q - Kitchen tiles", date: calendar.date(byAdding: .day, value: -2, to: today)!),
            
            Transaction(id: "txn-3", userId: userId, accountId: "acc-current",
                       categoryId: "cat-transport", amount: -65.40,
                       description: "Shell Petrol Station", date: calendar.date(byAdding: .day, value: -3, to: today)!),
            
            Transaction(id: "txn-4", userId: userId, accountId: "acc-current",
                       categoryId: "cat-entertainment", amount: -12.50,
                       description: "Vue Cinema", date: calendar.date(byAdding: .day, value: -4, to: today)!),
            
            Transaction(id: "txn-netflix", userId: userId, accountId: "acc-current",
                       categoryId: "cat-subscriptions", amount: -15.99,
                       description: "Netflix Subscription", date: calendar.date(byAdding: .day, value: -6, to: today)!),
            
            // Paris trip expenses (past event)
            Transaction(id: "txn-paris-1", userId: userId, accountId: "acc-current",
                       categoryId: "cat-food", eventId: "event-paris", amount: -45.80,
                       description: "Café de Flore", date: calendar.date(byAdding: .day, value: -9, to: today)!),
            
            Transaction(id: "txn-paris-2", userId: userId, accountId: "acc-current",
                       categoryId: "cat-transport", eventId: "event-paris", amount: -12.50,
                       description: "Paris Metro", date: calendar.date(byAdding: .day, value: -9, to: today)!),
            
            Transaction(id: "txn-paris-3", userId: userId, accountId: "acc-current",
                       categoryId: "cat-entertainment", eventId: "event-paris", amount: -89.00,
                       description: "Louvre Museum", date: calendar.date(byAdding: .day, value: -8, to: today)!),
            
            // Kitchen renovation expenses (ongoing event)
            Transaction(id: "txn-kitchen-1", userId: userId, accountId: "acc-current",
                       categoryId: "cat-shopping", eventId: "event-kitchen", amount: -1250.00,
                       description: "IKEA Kitchen Units", date: calendar.date(byAdding: .weekOfYear, value: -3, to: today)!),
            
            Transaction(id: "txn-kitchen-2", userId: userId, accountId: "acc-current",
                       categoryId: "cat-shopping", eventId: "event-kitchen", amount: -450.00,
                       description: "Wickes - Worktop", date: calendar.date(byAdding: .weekOfYear, value: -2, to: today)!),
            
            // INCOME TRANSACTIONS
            Transaction(id: "txn-5", userId: userId, accountId: "acc-current",
                       categoryId: "cat-salary", amount: 2800.00,
                       description: "Acme Corp Ltd", date: calendar.date(byAdding: .day, value: -5, to: today)!),
            
            Transaction(id: "txn-freelance", userId: userId, accountId: "acc-current",
                       categoryId: "cat-freelance", amount: 750.00,
                       description: "Design Project Payment", date: calendar.date(byAdding: .day, value: -10, to: today)!),
            
            Transaction(id: "txn-cashback", userId: userId, accountId: "acc-current",
                       categoryId: "cat-investment", amount: 15.67,
                       description: "Santander Cashback", date: calendar.date(byAdding: .day, value: -7, to: today)!),
            
            // Upcoming scheduled transactions
            Transaction(id: "txn-6", userId: userId, accountId: "acc-loan",
                       categoryId: nil, amount: -320.50,
                       description: "Car Finance Payment", date: calendar.date(byAdding: .day, value: 3, to: today)!,
                       isScheduled: true, recurrence: .monthly),
            
            Transaction(id: "txn-7", userId: userId, accountId: "acc-current",
                       categoryId: "cat-utilities", amount: -89.00,
                       description: "British Gas Bill", date: calendar.date(byAdding: .day, value: 7, to: today)!,
                       isScheduled: true, recurrence: .monthly),
            
            Transaction(id: "txn-8", userId: userId, accountId: "acc-current",
                       categoryId: "cat-utilities", amount: -45.00,
                       description: "BT Broadband", date: calendar.date(byAdding: .day, value: 12, to: today)!,
                       isScheduled: true, recurrence: .monthly),
            
            Transaction(id: "txn-9", userId: userId, accountId: "acc-credit",
                       categoryId: nil, amount: -75.00,
                       description: "Credit Card Payment", date: calendar.date(byAdding: .day, value: 15, to: today)!,
                       isScheduled: true, recurrence: .monthly),
            
            Transaction(id: "txn-10", userId: userId, accountId: "acc-current",
                       categoryId: "cat-utilities", amount: -125.00,
                       description: "Council Tax", date: calendar.date(byAdding: .day, value: 20, to: today)!,
                       isScheduled: true, recurrence: .monthly),
            
            // Scheduled income (salary)
            Transaction(id: "txn-salary-next", userId: userId, accountId: "acc-current",
                       categoryId: "cat-salary", amount: 2800.00,
                       description: "Acme Corp Ltd", date: calendar.date(byAdding: .day, value: 25, to: today)!,
                       isScheduled: true, recurrence: .monthly)
        ]
    }
    
    private static func createGolfClubTransactions(for userId: String, events: [Event], today: Date) -> [Transaction] {
        let calendar = Calendar.current
        
        return [
            // Top up transfer (money leaving current account)
            Transaction(id: "txn-current-golf", userId: userId, accountId: "acc-current",
                       categoryId: nil, amount: -100.00,
                       description: "Transfer to Golf Club Bar Card",
                       date: calendar.date(byAdding: .day, value: -10, to: today)!),
            
            // Top up transfer (money arriving in golf club account)
            Transaction(id: "txn-golf-topup", userId: userId, accountId: "acc-golf",
                       categoryId: nil, amount: 100.00,
                       description: "Top up from Current Account",
                       date: calendar.date(byAdding: .day, value: -10, to: today)!),
            
            // Golf club spending
            Transaction(id: "txn-golf-1", userId: userId, accountId: "acc-golf",
                       categoryId: "cat-entertainment", amount: -15.50,
                       description: "Drinks after round",
                       date: calendar.date(byAdding: .day, value: -8, to: today)!),
            
            Transaction(id: "txn-golf-2", userId: userId, accountId: "acc-golf",
                       categoryId: "cat-food", amount: -18.00,
                       description: "Club sandwich & coffee",
                       date: calendar.date(byAdding: .day, value: -5, to: today)!),
            
            Transaction(id: "txn-golf-3", userId: userId, accountId: "acc-golf",
                       categoryId: "cat-entertainment", amount: -12.50,
                       description: "Post-game pints",
                       date: calendar.date(byAdding: .day, value: -2, to: today)!),
            
            Transaction(id: "txn-golf-4", userId: userId, accountId: "acc-golf",
                       categoryId: "cat-food", amount: -6.50,
                       description: "Coffee & biscuits",
                       date: today)
        ]
    }
    
    private static func createFlexibleArrangementTransactions(for userId: String, today: Date) -> [Transaction] {
        let calendar = Calendar.current
        
        return [
            // Family loan payments (irregular amounts, showing flexibility)
            Transaction(id: "txn-family-1", userId: userId, accountId: "acc-family",
                       categoryId: nil, amount: -500.00,
                       description: "Payment to Parents",
                       date: calendar.date(byAdding: .month, value: -5, to: today)!),
            
            Transaction(id: "txn-family-2", userId: userId, accountId: "acc-family",
                       categoryId: nil, amount: -1000.00,
                       description: "Payment to Parents",
                       date: calendar.date(byAdding: .month, value: -3, to: today)!),
            
            Transaction(id: "txn-family-3", userId: userId, accountId: "acc-family",
                       categoryId: nil, amount: -750.00,
                       description: "Payment to Parents",
                       date: calendar.date(byAdding: .month, value: -1, to: today)!),
            
            Transaction(id: "txn-family-4", userId: userId, accountId: "acc-family",
                       categoryId: nil, amount: -750.00,
                       description: "Payment to Parents",
                       date: today),
            
            // Debt collection payments (more regular, smaller amounts)
            Transaction(id: "txn-debt-1", userId: userId, accountId: "acc-debt",
                       categoryId: nil, amount: -50.00,
                       description: "Lowell Group Payment",
                       date: calendar.date(byAdding: .month, value: -3, to: today)!),
            
            Transaction(id: "txn-debt-2", userId: userId, accountId: "acc-debt",
                       categoryId: nil, amount: -75.00,
                       description: "Lowell Group Payment",
                       date: calendar.date(byAdding: .month, value: -2, to: today)!),
            
            Transaction(id: "txn-debt-3", userId: userId, accountId: "acc-debt",
                       categoryId: nil, amount: -50.00,
                       description: "Lowell Group Payment",
                       date: calendar.date(byAdding: .month, value: -1, to: today)!),
            
            Transaction(id: "txn-debt-4", userId: userId, accountId: "acc-debt",
                       categoryId: nil, amount: -25.00,
                       description: "Lowell Group Payment",
                       date: calendar.date(byAdding: .day, value: -15, to: today)!),
            
            // Upcoming debt collection payment (scheduled)
            Transaction(id: "txn-debt-5", userId: userId, accountId: "acc-debt",
                       categoryId: nil, amount: -50.00,
                       description: "Lowell Group Payment",
                       date: calendar.date(byAdding: .day, value: 18, to: today)!, isScheduled: true, recurrence: .monthly)
        ]
    }
    
    private static func createBNPLTransactions(for userId: String, today: Date) -> [Transaction] {
        let calendar = Calendar.current
        
        return [
            // Klarna payments (first payment made, rest scheduled)
            Transaction(id: "txn-klarna-1", userId: userId, accountId: "acc-klarna",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-klarna-1", amount: -62.49,
                       description: "ASOS - Payment 1/4",
                       date: calendar.date(byAdding: .day, value: -14, to: today)!),
            
            Transaction(id: "txn-klarna-2", userId: userId, accountId: "acc-klarna",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-klarna-1", amount: -62.49,
                       description: "ASOS - Payment 2/4",
                       date: today, isScheduled: true),
            
            Transaction(id: "txn-klarna-3", userId: userId, accountId: "acc-klarna",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-klarna-1", amount: -62.49,
                       description: "ASOS - Payment 3/4",
                       date: calendar.date(byAdding: .day, value: 14, to: today)!, isScheduled: true),
            
            Transaction(id: "txn-klarna-4", userId: userId, accountId: "acc-klarna",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-klarna-1", amount: -62.48,
                       description: "ASOS - Payment 4/4",
                       date: calendar.date(byAdding: .day, value: 28, to: today)!, isScheduled: true),
            
            // Clearpay payments (first payment made, rest scheduled)
            Transaction(id: "txn-clearpay-1", userId: userId, accountId: "acc-clearpay",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-clearpay-1", amount: -40.00,
                       description: "John Lewis - Payment 1/4",
                       date: calendar.date(byAdding: .day, value: -7, to: today)!),
            
            Transaction(id: "txn-clearpay-2", userId: userId, accountId: "acc-clearpay",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-clearpay-1", amount: -40.00,
                       description: "John Lewis - Payment 2/4",
                       date: calendar.date(byAdding: .day, value: 7, to: today)!, isScheduled: true),
            
            Transaction(id: "txn-clearpay-3", userId: userId, accountId: "acc-clearpay",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-clearpay-1", amount: -39.99,
                       description: "John Lewis - Payment 3/4",
                       date: calendar.date(byAdding: .day, value: 21, to: today)!, isScheduled: true),
            
            Transaction(id: "txn-clearpay-4", userId: userId, accountId: "acc-clearpay",
                       categoryId: "cat-shopping", bnplPlanId: "bnpl-clearpay-1", amount: -40.00,
                       description: "John Lewis - Payment 4/4",
                       date: calendar.date(byAdding: .day, value: 35, to: today)!, isScheduled: true)
        ]
    }
    
    private static func createMockBNPLPlans(for userId: String, today: Date) -> [BNPLPlan] {
        let calendar = Calendar.current
        
        return [
            BNPLPlan(
                id: "bnpl-klarna-1",
                userId: userId,
                accountId: "acc-klarna",
                providerName: "Klarna",
                totalAmount: 249.95,
                numberOfInstallments: 4,
                frequency: .biweekly,
                startDate: calendar.date(byAdding: .day, value: -14, to: today)!,
                description: "ASOS Fashion Purchase"
            ),
            
            BNPLPlan(
                id: "bnpl-clearpay-1",
                userId: userId,
                accountId: "acc-clearpay",
                providerName: "Clearpay",
                totalAmount: 159.99,
                numberOfInstallments: 4,
                frequency: .biweekly,
                startDate: calendar.date(byAdding: .day, value: -7, to: today)!,
                description: "John Lewis Home Goods"
            )
        ]
    }
    
    private static func createMockFlexibleArrangements(for userId: String, today: Date) -> [FlexibleArrangement] {
        let calendar = Calendar.current
        
        return [
            FlexibleArrangement(
                id: "flex-family-1",
                userId: userId,
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
            ),
            
            FlexibleArrangement(
                id: "flex-debt-1",
                userId: userId,
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
        ]
    }
    
    private static func createMockTransfers(for userId: String, today: Date) -> [Transfer] {
        let calendar = Calendar.current
        
        return [
            Transfer(
                id: "transfer-golf-1",
                userId: userId,
                fromAccountId: "acc-current",
                toAccountId: "acc-golf",
                amount: 100.00,
                description: "Golf Club Bar Card",
                date: calendar.date(byAdding: .day, value: -10, to: today)!,
                transferType: .topUp
            )
        ]
    }
    
    private static func createMockBudgets(for userId: String, categories: [Category]) -> [Budget] {
        // Only create budgets for expense categories
        let expenseCategories = categories.filter { $0.categoryType == .expense }
        
        return [
            Budget(id: "budget-food", userId: userId, categoryId: "cat-food", amount: 400.00),
            Budget(id: "budget-transport", userId: userId, categoryId: "cat-transport", amount: 200.00),
            Budget(id: "budget-entertainment", userId: userId, categoryId: "cat-entertainment", amount: 150.00)
        ]
    }
}

// MARK: - Helper Models

/// Container for a complete set of mock data
struct MockDataSet {
    let user: User
    let accounts: [Account]
    let transactions: [Transaction]
    let categories: [Category]
    let budgets: [Budget]
    let bnplPlans: [BNPLPlan]
    let flexibleArrangements: [FlexibleArrangement]
    let transfers: [Transfer]
    let events: [Event]
}
