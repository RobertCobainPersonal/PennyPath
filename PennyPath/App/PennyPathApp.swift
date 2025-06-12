//
//  PennyPathApp.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

import SwiftUI

@main
struct PennyPathApp: App {
    // 1. Create a single instance of the AppStore for the app's lifecycle
    @StateObject private var appStore = AppStore()

    // Initialize Firebase when the app starts
    init() {
        FirebaseManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 2. Inject the store into the environment, making it available to all child views
                .environmentObject(appStore)
        }
    }
}
