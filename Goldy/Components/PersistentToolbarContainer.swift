//
//  PersistentToolbarContainer.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI

struct PersistentToolbarContainer<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            content
                // Ensure your main content can extend underneath the bar
                .edgesIgnoringSafeArea(.bottom)
            
            // The custom bar pinned at the bottom
            BottomToolbar()
                // Force it to hug the bottom edge
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}
