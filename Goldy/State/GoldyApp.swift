//
//  GoldyApp.swift
//  Goldy
//
//  Created by Blair Myers on 2/10/25.
//

import SwiftUI

@main
struct GoldyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
