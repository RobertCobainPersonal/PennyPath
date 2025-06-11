💳 PennyPath — Updated PRD (June 2025)

📌 tl;dr

PennyPath is a mobile-first personal finance iOS app (built in SwiftUI) focused on helping users manage credit-based financial products. The app supports tracking of credit cards, loans, BNPL agreements, budgeting, business expense tagging, and cash flow forecasting.

This updated PRD now introduces the MainTabView, a unified root navigation container that allows access to all major features including accounts, transactions, payments, budgeting, and settings.

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

Tab-based container

Access to Accounts, Payments, Add Transaction, Budget (placeholder), Settings (placeholder)

📆 In Progress: Add Transaction View + BNPL Logic

Purpose:

Create a SwiftUI interface and backend logic that allows a user to:

Add a normal or BNPL transaction

Generate scheduled payments based on selected BNPL plan

Update account balances accordingly

🔍 Prompt for Coding AI (MainTabView Navigation)

struct MainTabView: View {
    var body: some View {
        TabView {
            AccountListView()
                .tabItem {
                    Label("Accounts", systemImage: "creditcard")
                }

            ScheduledPaymentsListView()
                .tabItem {
                    Label("Payments", systemImage: "calendar.badge.clock")
                }

            AddTransactionView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }

            BudgetsView() // Placeholder
                .tabItem {
                    Label("Budget", systemImage: "chart.pie.fill")
                }

            SettingsView() // Placeholder
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

To enable, update your App.swift to display MainTabView() after login.

📈 Remaining MVP Features

Complete AddTransactionView and payment generation logic

Budgets by category + budget progress

Cash flow forecast + alerts

Event tagging + business expense receipts

Final polish & test
