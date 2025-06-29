//
//  SignupView.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI
import Combine

// MARK: - SignupView
struct SignupView: View {
    @ObservedObject var viewModel = SignupViewModel()
    
    // Simple, naive check for demonstration:
    private var isValidEmail: Bool {
        let trimmed = viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
        // Basic check: has '@' and '.'
        return trimmed.contains("@") && trimmed.contains(".")
    }
    
    var body: some View {
        ZStack {
            // Background
            AppBackgroundView()
            
            // Main Content
            SignupMainContentView(viewModel: viewModel, isValidEmail: isValidEmail)
        }
        // If sign-up is successful, show success or navigate away
        .fullScreenCover(isPresented: $viewModel.isSignedUp) {
            Text("Account Created Successfully!")
                .font(.largeTitle)
        }
    }
}

#Preview {
    SignupView()
}

// MARK: - Subviews

/// The main container for sign-up fields, buttons, and text.
private struct SignupMainContentView: View {
    @ObservedObject var viewModel: SignupViewModel
    let isValidEmail: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            // Title
            SignupTitleView()
            
            // EMAIL with trailing checkmark if valid
            SignupEmailFieldView(email: $viewModel.email, isValidEmail: isValidEmail)
                .padding(.bottom, 16)
            
            // NAME
            LabeledTextField(
                label: "NAME",
                placeholder: "Enter name",
                text: $viewModel.name,
                isSecure: false
            )
            .padding(.bottom, 16)
            
            // PASSWORD
            LabeledTextField(
                label: "PASSWORD",
                placeholder: "",
                text: $viewModel.password,
                isSecure: true
            )
            .padding(.bottom, 50)
            
            // SIGN UP Button
            PrimaryActionButton(title: "SIGN UP") {
                viewModel.signUp()
            }
            
            // Error message if needed
            SignupErrorMessageView(errorMessage: viewModel.errorMessage)
            
            // “have an account? log in” link
            SignupLoginLinkView()
            
            Spacer()
            
            // Footer disclaimers
            SignupFooterView()
        }
        .padding(.horizontal, 15)
    }
}

/// “SIGN UP” title at the top of the screen.
private struct SignupTitleView: View {
    var body: some View {
        Text("SIGN UP")
            .font(.custom("DelaGothicOne-Regular", size: 30))
            .padding(.top, 190)  // Large top padding
            .padding(.bottom, 60)
    }
}

/// A custom view for the email field, including the trailing checkmark if valid.
private struct SignupEmailFieldView: View {
    @Binding var email: String
    let isValidEmail: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EMAIL")
                .font(.custom("DelaGothicOne-Regular", size: 16))
                .foregroundColor(.black)
            
            ZStack(alignment: .trailing) {
                TextField("Enter email", text: $email)
                    .padding()
                    .frame(height: 35)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .font(.body)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.none)
                
                if isValidEmail {
                    Image(systemName: "checkmark")
                        .padding(.trailing, 12)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

/// Displays an error message if `errorMessage` is not empty.
private struct SignupErrorMessageView: View {
    let errorMessage: String
    
    var body: some View {
        if !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundColor(.red)
                .font(.callout)
                .padding(.top, 8)
        }
    }
}

/// “have an account? log in” link at the bottom of the form.
private struct SignupLoginLinkView: View {
    var body: some View {
        HStack {
            Spacer()
            Text("have an account?")
                .foregroundColor(.black)
            Button(action: {
                // Navigate back to Login
            }) {
                Text("log in")
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

/// The footer disclaimers at the bottom of the screen.
private struct SignupFooterView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 2) {
                Text("By signing up you agree to our ")
                    .foregroundColor(.gray)
                    .font(.custom("DelaGothicOne-Regular", size: 10))
                +
                Text("Terms of Use")
                    .foregroundColor(.gray)
                    .underline()
                    .font(.custom("DelaGothicOne-Regular", size: 10))
                +
                Text(" and our ")
                    .foregroundColor(.gray)
                    .font(.custom("DelaGothicOne-Regular", size: 10))
                +
                Text("Privacy Policy")
                    .foregroundColor(.gray)
                    .underline()
                    .font(.custom("DelaGothicOne-Regular", size: 10))
            }
            .multilineTextAlignment(.center)
            .padding(.bottom, 40)
            Spacer()
        }
    }
}
