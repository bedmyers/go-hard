//
//  RootView.swift
//  Goldy
//
//  Created by Blair Myers on 6/28/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var escrowViewModel = EscrowViewModel()

    var body: some View {
        let _ = print("🔍 DEBUG: RootView body called - isAuthenticated: \(appState.isAuthenticated)")
        
        if appState.isAuthenticated {
            let _ = print("🔍 DEBUG: User is authenticated, showing OpenEscrowsView")
            NavigationStack {
                OpenEscrowsView(viewModel: escrowViewModel)
            }
        } else {
            let _ = print("🔍 DEBUG: User not authenticated, showing IntroView")
            IntroView()
        }
    }
}
