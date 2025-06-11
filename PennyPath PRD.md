💳 PennyPath — Updated PRD (June 2025)

📌 tl;dr

PennyPath is a mobile-first personal finance iOS app (built in SwiftUI) focused on helping users manage credit-based financial products. The app supports tracking of credit cards, loans, BNPL agreements, budgeting, business expense tagging, and cash flow forecasting.

This updated PRD reflects progress to date and introduces a user-defined BNPL plan system, a transaction-first BNPL architecture, and an upcoming payment scheduling model for accurate forecasting.

🌟 Goals

Business Goals

Deliver a functional MVP in SwiftUI for iOS with Firebase backend

Build a credit-first finance tracking experience

Implement smart forecasting, budgeting, and alerting

Show debt reduction and upcoming obligations clearly

User Goals

Track real-time balances across credit products

Add historical and future transactions with accurate balance tracking

Schedule BNPL and recurring credit payments

Set monthly budgets and receive cash flow alerts

Tag and organize expenses by event or business purpose

Define custom BNPL repayment plans to reflect provider-specific terms

✅ Progress to Date (as of June 2025)

✅ Firebase Auth Integration Completed

✅ Account Model and Add Account View Completed

✅ BNPL Plan Model and View Completed

✅ Transaction Model Implemented

Supports both standard and BNPL transactions

Includes reference to BNPL plans, initial and fee amounts, linked accounts, and future scheduled payments

🔧 Updated Firestore transactions/{transactionId} Schema

{
  "id": "txn_001",
  "accountId": "bnpl_zilch_01",
  "linkedAccountId": "monzo_main",
  "amount": 120.00,
  "date": "2025-06-15",
  "category": "Electronics",
  "description": "Headphones",
  "isBNPL": true,
  "bnplPlanId": "plan_zilch6wk",
  "initialPaymentAmount": 30.00,
  "feeAmount": 4.99,
  "scheduledPaymentIds": ["sp_01", "sp_02", "sp_03"]
}

📝 Next Step: Scheduled Payment Model

Purpose:

Enable the app to track, visualize, and forecast upcoming BNPL or recurring credit payments tied to transactions.

Model: ScheduledPayment

struct ScheduledPayment: Identifiable, Codable {
    var id: String
    var transactionId: String
    var dueDate: Date
    var amount: Double
    var sourceAccountId: String
    var paid: Bool
    var paymentDate: Date?
}

These scheduled payments will:

Be generated automatically when a BNPL transaction is created

Update balances on both the funding account and BNPL account when marked as paid

Feed into the cash flow forecasting engine

🔍 Prompt for Coding AI (Scheduled Payments Model)

We’ve built a SwiftUI app for finance tracking (PennyPath) and completed Auth, Account, BNPLPlan, and Transaction models. Now we need a model to handle future BNPL and credit payment scheduling.

### Task: Create the ScheduledPayment model in Swift

### Requirements:
- Track individual payments from BNPL or recurring transactions
- Must include:
  - `id`, `transactionId`, `dueDate`, `amount`
  - `sourceAccountId`: which account the payment is drawn from
  - `paid: Bool`
  - `paymentDate`: optional timestamp of when payment was made

### Output:
- Swift `ScheduledPayment` model (Codable, Identifiable)
- No need to write Firestore write logic or UI yet

📊 Prompt Guidelines for Next AI Steps

"Use this PRD and help me implement the ScheduledPayment model."

"Now that I have a transaction and payment model, help me create logic to generate scheduled payments based on the selected BNPL plan."

📈 Remaining MVP Features

View accounts and transactions from Firestore

Add Transaction view

Generate and track scheduled payments

Budgets by category + budget progress

Cash flow forecast + alerts

Event tagging + business expense receipts

Home dashboard

Final polish & test
