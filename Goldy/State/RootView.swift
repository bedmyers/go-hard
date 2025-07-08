//
//  RootView.swift
//  Goldy
//
//  Created by Blair Myers on 6/28/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.isAuthenticated {
            NavigationStack {
                OpenEscrowsView(viewModel: EscrowViewModel())
            }
        } else {
            IntroView()
        }
    }
}
