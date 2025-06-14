//
//  MainTabView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // --- NEW: Dashboard is now the first tab ---
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            // --- MOVED: Accounts is now the second tab ---
            AccountListView()
                .tabItem {
                    Label("Accounts", systemImage: "creditcard")
                }
            
            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }

            ScheduledPaymentsListView()
                .tabItem {
                    Label("Payments", systemImage: "calendar.badge.clock")
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


