//
//  VendorTabView.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI

struct VendorTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "house.fill")
                }
            
            VendorDiscoverView()
                .tabItem {
                    Label("RFPs", systemImage: "doc.text.magnifyingglass")
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

#Preview {
    VendorTabView()
        .environmentObject(AppState())
}
