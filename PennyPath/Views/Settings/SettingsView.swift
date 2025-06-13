//
//  SettingsView.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Configuration")) {
                    NavigationLink("Manage Categories") {
                        CategoryManagementView()
                    }
                    
                    NavigationLink("Manage BNPL Plans") {
                        BNPLPlanListView()
                    }
                }
                
                // We can add more settings sections here in the future
                // e.g., Profile, App Settings, etc.
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
