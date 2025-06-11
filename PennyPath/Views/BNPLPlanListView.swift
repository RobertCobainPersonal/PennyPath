//
//  BNPLPlanListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//


//
//  BNPLPlanListView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import SwiftUI

struct BNPLPlanListView: View {
    
    @StateObject private var viewModel = BNPLPlanListViewModel()
    @State private var showingAddPlanSheet = false
    
    var body: some View {
        Group {
            if viewModel.plans.isEmpty {
                ContentUnavailableView(
                    "No BNPL Plans",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Tap the '+' button to create your first reusable BNPL plan.")
                )
            } else {
                List(viewModel.plans) { plan in
                    VStack(alignment: .leading) {
                        Text(plan.planName)
                            .fontWeight(.semibold)
                        Text(plan.provider)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("BNPL Plans")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddPlanSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPlanSheet) {
            AddBNPLPlanView()
        }
        .onAppear {
            viewModel.fetchPlans()
        }
    }
}

struct BNPLPlanListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BNPLPlanListView()
        }
    }
}