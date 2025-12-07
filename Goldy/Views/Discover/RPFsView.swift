//
//  RPFsView.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI

struct RFPsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("Browse RFPs")
                        .font(.custom("DelaGothicOne-Regular", size: 20))
                    
                    Text("Available projects you can bid on")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("RFPs")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    RFPsView()
}
