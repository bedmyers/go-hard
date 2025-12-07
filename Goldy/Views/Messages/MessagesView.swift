//
//  Messages.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI

struct MessagesView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Messages")
                        .font(.custom("DelaGothicOne-Regular", size: 20))
                    
                    Text("Your conversations will appear here")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    MessagesView()
}
