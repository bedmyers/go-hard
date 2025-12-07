//
//  RootView.swift
//  Goldy
//
//  Created by Blair Myers on 6/28/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var connectViewModel = VendorOnboardingViewModel()

    var body: some View {
        let _ = print("🔍 DEBUG: RootView body called - isAuthenticated: \(appState.isAuthenticated)")
        
        if appState.isAuthenticated {
            let _ = print("🔍 DEBUG: User is authenticated")
            let _ = print("🔍 DEBUG: User type: \(appState.currentUser?.userType.rawValue ?? "unknown")")
            
            if appState.currentUser?.userType == .vendor {
                VendorRootView(
                    connectViewModel: connectViewModel
                )
            } else {
                // Customer flow - show tab bar
                CustomerTabView()
            }
        } else {
            let _ = print("🔍 DEBUG: User not authenticated, showing IntroView")
            IntroView()
        }
    }
}

// MARK: - Vendor Root View
private struct VendorRootView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var connectViewModel: VendorOnboardingViewModel
    @State private var showWelcome = true
    @State private var showProfileSetup = false
    
    var body: some View {
        ZStack {
            // Show vendor tabs
            VendorTabView()
                .environmentObject(connectViewModel)
            
            // Welcome overlay (first time only)
            if showWelcome && !hasSeenWelcome {
                VendorWelcomeView {
                    showProfileSetup = true
                    showWelcome = false
                    markWelcomeAsSeen()
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showProfileSetup) {
            VendorQuickProfileView()
        }
    }
    
    private var hasSeenWelcome: Bool {
        UserDefaults.standard.bool(forKey: "hasSeenVendorWelcome")
    }
    
    private func markWelcomeAsSeen() {
        UserDefaults.standard.set(true, forKey: "hasSeenVendorWelcome")
    }
}
