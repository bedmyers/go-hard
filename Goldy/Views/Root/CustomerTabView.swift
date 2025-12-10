//
//  CustomerTabView.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI

struct CustomerTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "house.fill")
                }
            
            Group {
                if appState.currentUser?.userType == .vendor || appState.currentUser?.userType == .both {
                    VendorDiscoverView()
                } else {
                    DiscoverView()
                }
            }
            .tabItem {
                Label("Discover", systemImage: "magnifyingglass")
            }
            
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .accentColor(.black)
    }
}
