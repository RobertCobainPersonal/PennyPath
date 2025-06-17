//
//  MainTabView.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var selectedTab = 0
    @State private var showingQuickActions = false
    @State private var showGlobalFAB = true // NEW: Control FAB visibility
    
    var body: some View {
        ZStack {
            // Main tab view
            TabView(selection: $selectedTab) {
                // Dashboard Tab
                DashboardView(appStore: appStore)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                // Accounts Tab
                AccountsListView(appStore: appStore)
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "building.columns.fill" : "building.columns")
                        Text("Accounts")
                    }
                    .tag(1)
                
                // Transactions Tab (Placeholder for now)
                TransactionsPlaceholderView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "creditcard.fill" : "creditcard")
                        Text("Transactions")
                    }
                    .tag(2)
                
                // Budgets Tab (Placeholder for now)
                BudgetsPlaceholderView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                        Text("Budgets")
                    }
                    .tag(3)
            }
            .accentColor(.blue)
            
            // Floating Action Button (conditionally shown)
            if showGlobalFAB {
                FloatingActionButton(isExpanded: $showingQuickActions)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("HideGlobalFAB"))) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showGlobalFAB = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowGlobalFAB"))) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showGlobalFAB = true
            }
        }
    }
}

// MARK: - Placeholder Views (Will be replaced with real implementations)

struct TransactionsPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "creditcard")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Transactions")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("View and manage all your transactions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct BudgetsPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Budgets")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Set and track your spending budgets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview Provider
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppStore())
    }
}
