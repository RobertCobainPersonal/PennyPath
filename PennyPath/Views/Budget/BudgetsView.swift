//
//  BudgetsView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import SwiftUI

struct BudgetsView: View {
    @StateObject private var viewModel = BudgetListViewModel()
    @EnvironmentObject var store: AppStore
    
    @State private var showingAddBudgetSheet = false
    
    var body: some View {
        NavigationView {
            List(viewModel.budgetProgressList) { progressItem in
                BudgetRowView(budgetProgress: progressItem)
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddBudgetSheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBudgetSheet) {
                AddBudgetView()
            }
            .onAppear {
                // Tell the ViewModel to start listening for data from the AppStore
                viewModel.listenForData(store: store)
            }
        }
    }
}

struct BudgetsView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetsView()
            .environmentObject(AppStore()) // Provide a dummy store for the preview
    }
}
