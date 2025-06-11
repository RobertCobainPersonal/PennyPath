💳 PennyPath — Updated PRD (June 2025)

📌 tl;dr

PennyPath is a mobile-first personal finance iOS app (built in SwiftUI) focused on helping users manage credit-based financial products. The app supports tracking of credit cards, loans, BNPL agreements, budgeting, business expense tagging, and cash flow forecasting.

The app now includes a working root navigation shell (MainTabView) and has implemented the foundational data models and basic views. We are moving into the next phase: building transaction logic, refreshing state between views, and fleshing out the full feature set.

🌟 Goals

Business Goals

Deliver a functional MVP in SwiftUI for iOS with Firebase backend

Build a credit-first finance tracking experience

Implement smart forecasting, budgeting, and alerting

Show debt reduction and upcoming obligations clearly

User Goals

Track real-time balances across credit products

Add historical and future transactions with accurate balance tracking

Schedule BNPL, recurring credit, and general transfers or payments

Set monthly budgets and receive cash flow alerts

Tag and organize expenses by event or business purpose

Define custom BNPL repayment plans to reflect provider-specific terms

Navigate seamlessly across the app using a unified tab bar

✅ Progress to Date (as of June 2025)

✅ Firebase Auth Integration Completed

✅ Account Model and Add Account View Completed

✅ BNPL Plan Model and View Completed

✅ Transaction Model Implemented

✅ ScheduledPayment Model Implemented (Reusable)

✅ Scheduled Payments List View Implemented

✅ MainTabView Created

📆 In Progress

AddTransactionView + BNPL Logic

User can add a normal or BNPL transaction

BNPL plans define installment frequency and fees

ScheduledPayments auto-generated upon submission

Balance updates cascade to linked accounts

Upcoming Development Tasks

1. TransactionService (HIGH)

Abstract Firestore write logic for transactions

Include addTransaction, fetchTransactions(forAccountId:)

Handle linking of scheduled payments and balance updates

2. BNPL Plan Creation View (HIGH)

User-defined plans: duration, frequency, fee logic

Required for submitting BNPL transactions

3. View Refresh Infrastructure (HIGH)

Ensure views like AddTransactionView update after new accounts or plans

Use ObservableObject + @Published store for app-wide state sync

4. AccountDetailView (MED)

View transactions for a specific account

Include scheduled payments and visual balance

5. Transfer as a Transaction (MED)

Logic to create two-sided transactions (source/target account)

Update both balances on commit

6. Category Management View (LOW)

Add, edit, and manage categories

Used in AddTransactionView and future budgeting screens

🔍 Prompt for Coding AI: TransactionService.swift

We’re building a SwiftUI iOS app using Firebase called PennyPath. We've implemented models for Accounts, Transactions, ScheduledPayments, and BNPLPlans. Now we need to implement a TransactionService that handles:

- Saving new transactions to Firestore
- Creating scheduled payments linked to a transaction
- Updating source and target account balances (support for transfers)

### Requirements:
- Swift class or struct: TransactionService
- Methods:
  - `addTransaction(_:)`
  - `fetchTransactions(for accountId: String)`
  - Logic to attach scheduled payments if provided
- Use `async/await` and `FirebaseFirestoreSwift`
- Modular, documented code

📈 Remaining MVP Features

Implement TransactionService

Add BNPL Plan Creation UI

Add AccountDetailView

Build category management UI

Add transfer logic

Wire up global app refresh state

Implement budgets + forecasting

Final polish & test
