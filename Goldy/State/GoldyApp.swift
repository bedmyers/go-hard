//
//  GoldyApp.swift
//  Goldy
//
//  Created by Blair Myers on 2/10/25.
//

import SwiftUI
import StripeCore

@main
struct GoldyApp: App {
    @StateObject private var appState = AppState()

    init() {
        let pk = Bundle.main.object(forInfoDictionaryKey: "STRIPE_PUBLISHABLE_KEY") as? String ?? ""
        precondition(!pk.isEmpty, "Add STRIPE_PUBLISHABLE_KEY to Info.plist")
        StripeAPI.defaultPublishableKey = pk
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
