//
//  IntroView.swift
//  Goldy
//
//  Created by Blair Myers on 2/26/25.
//

import SwiftUI

// MARK: - IntroView
struct IntroView: View {
    // This state variable controls which sheet is shown
    @State private var showLogin = false
    @State private var showSignup = false
    
    var body: some View {
        ZStack {
            // Reusable background
            AppBackgroundView()
            
            VStack {
                IntroTitleView()
                
                Spacer()
                
                // Get Started Button
                PrimaryActionButton(title: "GET STARTED") {
                    showSignup.toggle()
                }
                .padding(.horizontal, 17)
                .padding(.bottom, 43)
                
                // Login Option
                IntroLoginOptionView {
                    showLogin.toggle()
                }
                .padding(.bottom, 144)
            }
        }
        // Show the Login or Signup sheets
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
        .sheet(isPresented: $showSignup) {
            SignupView()
        }
    }
}

#Preview {
    IntroView()
}

// MARK: - Subviews

/// The large title text on the Intro screen.
private struct IntroTitleView: View {
    var body: some View {
        Text("SAFELY\nHOLD AND\nRELEASE\nYOUR\nPAYMENTS")
            .font(.custom("DelaGothicOne-Regular", size: 45))
            .multilineTextAlignment(.leading)
            .foregroundColor(.black)
            .padding(.leading, 25)
            .padding(.top, 110)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small view prompting the user to log in if they already have an account.
private struct IntroLoginOptionView: View {
    let loginAction: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text("have an account?")
                .font(.custom("DelaGothicOne-Regular", size: 16))
            
            Button(action: {
                loginAction()
            }) {
                Text("log in")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.red)
                    .underline()
            }
        }
    }
}
