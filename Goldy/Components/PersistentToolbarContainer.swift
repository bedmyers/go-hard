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
                .edgesIgnoringSafeArea(.bottom)
            
            BottomToolbar()
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}
