//
//  ContentView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

import SwiftUI

struct ContentView: View {
    // Create and hold the single instance of AuthViewModel for the app's lifecycle
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.userSession == nil {
                // User is not logged in, show the authentication flow
                LoginView()
            } else {
                // User is logged in, show the main app content
                AccountListView()
            }
        }
        // Provide the viewModel to all child views
        .environmentObject(authViewModel)
    }
}

#Preview {
    ContentView()
}
