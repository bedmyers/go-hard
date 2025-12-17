//
//  ProfileView.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI

struct ProfileViewOld: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.custom("Spectral-Regular", size: 80))
                        .foregroundColor(.gray)
                    
                    if let user = appState.currentUser {
                        Text(user.name)
                            .font(.custom("DelaGothicOne-Regular", size: 24))
                        
                        Text(user.email)
                            .font(.custom("Spectral-Regular", size: 15))
                            .foregroundColor(.gray)
                        
                        Text(user.userType.rawValue)
                            .font(.custom("Spectral-Medium", size: 13))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color(hex: "7C3AED"))
                            .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // Logout button
                    Button {
                        appState.logout()
                    } label: {
                        Text("LOG OUT")
                            .font(.custom("DelaGothicOne-Regular", size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ProfileViewOld()
        .environmentObject(AppState())
}
