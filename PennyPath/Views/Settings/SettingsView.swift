//
//  SettingsView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import SwiftUI

struct SettingsView: View {
    
    // 1. State to control the presentation of the sheet
    @State private var showingCategoryManagement = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Configuration")) {
                    // 2. Changed NavigationLink to a Button
                    Button("Manage Categories") {
                        showingCategoryManagement.toggle()
                    }
                    
                    NavigationLink("Manage BNPL Plans") {
                        BNPLPlanListView()
                    }
                }
                
                // We can add more settings sections here in the future
                // e.g., Profile, App Settings, etc.
            }
            .navigationTitle("Settings")
            // 3. Added the .sheet modifier to present the view
            .sheet(isPresented: $showingCategoryManagement) {
                // We wrap the CategoryManagementView in its own NavigationView
                // so it gets a title bar and its own toolbar items inside the sheet.
                NavigationView {
                    CategoryManagementView()
                        .navigationBarItems(trailing: Button("Done") {
                            showingCategoryManagement.toggle()
                        })
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
