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
            AccountListView()
                .tabItem {
                    Label("Accounts", systemImage: "creditcard")
                }
            
            // The new Transactions tab
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
