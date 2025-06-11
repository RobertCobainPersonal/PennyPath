💳 PennyPath — Updated PRD (June 2025)

📌 tl;dr

PennyPath is a mobile-first personal finance iOS app (built in SwiftUI) focused on helping users manage credit-based financial products. The app supports tracking of credit cards, loans, BNPL agreements, budgeting, business expense tagging, and cash flow forecasting.

This updated PRD reflects a now working backend foundation including user-defined BNPL plans, a transaction-first architecture, and a flexible recurring payment model that will power all future debt, subscription, and transfer schedules.

⸻

🌟 Goals

Business Goals
	•	Deliver a functional MVP in SwiftUI for iOS with Firebase backend
	•	Build a credit-first finance tracking experience
	•	Implement smart forecasting, budgeting, and alerting
	•	Show debt reduction and upcoming obligations clearly

User Goals
	•	Track real-time balances across credit products
	•	Add historical and future transactions with accurate balance tracking
	•	Schedule BNPL, recurring credit, and general transfers or payments
	•	Set monthly budgets and receive cash flow alerts
	•	Tag and organize expenses by event or business purpose
	•	Define custom BNPL repayment plans to reflect provider-specific terms

⸻

✅ Progress to Date (as of June 2025)
	•	✅ Firebase Auth Integration Completed
	•	✅ Account Model and Add Account View Completed
	•	✅ BNPL Plan Model and View Completed
	•	✅ Transaction Model Implemented
	•	✅ ScheduledPayment Model Implemented (Reusable)
	•	Supports all future recurring payments: BNPL, loan repayments, credit card minimums, recurring transfers, bills, and cash flow projections
	•	Designed with optional transactionId to decouple from transaction-only logic

⸻

📆 New: ScheduledPayment Model (Generalized)

struct ScheduledPayment: Identifiable, Codable {
    var id: String
    var transactionId: String?
    var dueDate: Date
    var amount: Double
    var sourceAccountId: String
    var targetAccountId: String?
    var paid: Bool
    var paymentDate: Date?
    var recurrence: RecurrenceType?      // weekly, monthly, etc.
    var isAutoPayEnabled: Bool?
    var notes: String?
}

enum RecurrenceType: String, Codable {
    case none, weekly, biweekly, monthly, quarterly, yearly
}


⸻

🔍 Prompt for Coding AI (ScheduledPayment UI View)

We have a fully working model for ScheduledPayment that includes support for all types of recurring payments (BNPL, loan, transfer, bills, etc.).

### Task: Build a SwiftUI view to display a list of upcoming ScheduledPayments for the logged-in user

### Requirements:
- Query Firestore for `scheduled_payments` tied to the current user
- Filter: only show upcoming payments (where `paid == false` and `dueDate >= now`)
- Group by `dueDate` or `account`
- Display:
  - `dueDate`, `amount`, `sourceAccountId`, `targetAccountId`, recurrence icon (if applicable)
  - Mark payment as paid with a toggle or swipe action
- Add navigation bar title and empty state

### Output:
- Full SwiftUI View code
- Firestore query logic
- Optional: preview data for SwiftUI canvas


⸻

📊 Prompt Guidelines for Next AI Steps

“Use this PRD and help me build the UI to display upcoming scheduled payments for testing.”

“After that, help me generate payments dynamically from a BNPL transaction and plan.”

⸻

📈 Remaining MVP Features
	•	View accounts and transactions from Firestore
	•	Add Transaction view with BNPL support
	•	Generate and track scheduled payments
	•	Budgets by category + budget progress
	•	Cash flow forecast + alerts
	•	Event tagging + business expense receipts
	•	Home dashboard
	•	Final polish & test
