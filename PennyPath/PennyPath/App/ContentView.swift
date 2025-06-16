//
//  ContentView.swift
//  PennyPath
//
//  Created by Robert Cobain on 15/06/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appStore: AppStore
    
    var body: some View {
        DashboardView(appStore: appStore)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppStore())
    }
}
