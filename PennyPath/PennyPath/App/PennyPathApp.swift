//
//  PennyPathApp.swift
//  PennyPath
//
//  Created by Robert Cobain on 15/06/2025.
//

import SwiftUI
import Firebase

@main
struct PennyPathApp: App {
    @StateObject private var appStore = AppStore()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if appStore.isAuthenticated {
                ContentView()
                    .environmentObject(appStore)
            } else {
                AuthenticationView()
                    .environmentObject(appStore)
            }
        }
    }
}
