//
//  LoginView.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI

// MARK: - LoginView
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var authVM = AuthViewModel()
    @State private var showSignup = false
    
    var body: some View {
        ZStack {
            // Background
            AppBackgroundView()
            
            // Main Content
            LoginMainContentView(authVM: authVM)
        }
        .onChange(of: authVM.isAuthenticated) { isAuthed in
            if isAuthed {
                appState.isAuthenticated = true
            }
        }
    }
}

#Preview {
    LoginView()
}

// MARK: - Subviews

/// The main container that holds the login title, fields, button, error message, and footer.
private struct LoginMainContentView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var authVM: AuthViewModel
    @State private var showSignup = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // Title
            LoginTitleView()
            
            // EMAIL
            LabeledTextField(
                label: "EMAIL",
                placeholder: "Enter email",
                text: $authVM.email,
                isSecure: false
            )
            .padding(.bottom, 16)
            
            // PASSWORD + "FORGOT PASSWORD?"
            LoginPasswordView(password: $authVM.password)
                .padding(.bottom, 30)
            
            // LOG IN button
            PrimaryActionButton(title: "LOG IN") {
                authVM.login()
            }
            
            // Error message if needed
            LoginErrorMessageView(errorMessage: authVM.errorMessage)
            
            LoginFooterView {
                showSignup = true
            }
            
            Spacer()
        }
        .sheet(isPresented: $showSignup) {
            SignupView()
                .environmentObject(appState)
        }
        .padding(.horizontal, 15)
    }
}

/// The “LOG IN” title with the same layout & padding.
private struct LoginTitleView: View {
    var body: some View {
        Text("LOG IN")
            .font(.custom("DelaGothicOne-Regular", size: 30))
            // Increase top padding to move title further down
            .padding(.top, 190)
            .padding(.bottom, 60)
    }
}

/// The combined password field (label + secure field) and "FORGOT PASSWORD?" link.
private struct LoginPasswordView: View {
    @Binding var password: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("PASSWORD")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.black)
            }
            .padding(.bottom, 8)
            
            SecureField("", text: $password)
                .padding()
                .frame(height: 35)
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
                .font(.body)
                .padding(.bottom, 8)
            
            Button(action: {
                // Forgot password action
            }) {
                Text("FORGOT PASSWORD?")
                    .font(.custom("DelaGothicOne-Regular", size: 13))
                    .foregroundColor(.gray)
            }
        }
    }
}

/// Displays an error message if there is one.
private struct LoginErrorMessageView: View {
    let errorMessage: String
    
    var body: some View {
        if !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundColor(.red)
                .font(.callout)
        }
    }
}

private struct LoginFooterView: View {
    var onSignupTapped: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Text("don’t have an account?")
                .foregroundColor(.black)
            Button(action: onSignupTapped) {
                Text("sign up")
                    .foregroundColor(.red)
                    .fontWeight(.bold)
                    .underline()
            }
            Spacer()
        }
        .font(.custom("DelaGothicOne-Regular", size: 16))
        .padding(.top, 36)
    }
}

// MARK: - MainEscrowView
struct MainEscrowView: View {
    var body: some View {
        Text("You are logged in! Show escrow data here.")
            .font(.title)
    }
}
