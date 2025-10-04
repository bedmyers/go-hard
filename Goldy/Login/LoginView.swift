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
    @StateObject private var authVM = AuthViewModel()
    @FocusState private var focusedField: LoginField?
    @Environment(\.dismiss) private var dismiss
    @State private var showSignup = false
    @State private var showForgotPassword = false
    
    enum LoginField {
        case email, password
    }
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            ScrollView {
                LoginMainContentView(
                    authVM: authVM,
                    focusedField: $focusedField,
                    showSignup: $showSignup,
                    showForgotPassword: $showForgotPassword
                )
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onChange(of: authVM.isAuthenticated) { isAuthed in
            if isAuthed {
                let token = UserDefaults.standard.string(forKey: "authToken") ?? ""
                let userId = UserDefaults.standard.integer(forKey: "userId")
                
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                print("DEBUG: LoginView calling appState.login with userId: \(userId)")
                appState.login(token: token, userId: userId)
                
                dismiss()
            }
        }
        .fullScreenCover(isPresented: $showSignup) {
            SignupView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(email: authVM.email)
                .presentationDetents([.medium])
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

// MARK: - Main Content View
private struct LoginMainContentView: View {
    @ObservedObject var authVM: AuthViewModel
    @FocusState.Binding var focusedField: LoginView.LoginField?
    @Binding var showSignup: Bool
    @Binding var showForgotPassword: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LoginTitleView()
            
            LoginEmailFieldView(
                email: $authVM.email,
                validationState: authVM.emailValidationState,
                isLoading: authVM.isLoading
            )
            .focused($focusedField, equals: .email)
            .onSubmit { focusedField = .password }
            .padding(.bottom, 16)
            
            LoginPasswordFieldView(
                password: $authVM.password,
                isLoading: authVM.isLoading,
                onForgotPassword: { showForgotPassword = true }
            )
            .focused($focusedField, equals: .password)
            .onSubmit {
                if authVM.canSubmit {
                    focusedField = nil
                    authVM.login()
                }
            }
            .padding(.bottom, 30)
            
            LoginButtonView(
                isLoading: authVM.isLoading,
                canSubmit: authVM.canSubmit,
                action: {
                    focusedField = nil
                    authVM.login()
                }
            )
            
            if !authVM.errorMessage.isEmpty {
                ErrorMessageView(message: authVM.errorMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture {
                        authVM.clearError()
                    }
            }
            
            LoginFooterView(onSignupTapped: { showSignup = true })
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 15)
        .animation(.easeInOut(duration: 0.2), value: authVM.errorMessage)
    }
}

// MARK: - Title View
private struct LoginTitleView: View {
    var body: some View {
        Text("LOG IN")
            .font(.custom("DelaGothicOne-Regular", size: 30))
            .padding(.top, 100)
            .padding(.bottom, 40)
    }
}

// MARK: - Email Field View
private struct LoginEmailFieldView: View {
    @Binding var email: String
    let validationState: ValidationState
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("EMAIL")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.black)
                
                if case .invalid(let message) = validationState {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            ZStack(alignment: .trailing) {
                TextField("Enter email", text: $email)
                    .padding()
                    .frame(height: 50)
                    .background(fieldBackground)
                    .cornerRadius(8)
                    .overlay(fieldBorder)
                    .font(.body)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.none)
                    .disabled(isLoading)
                
                if case .valid = validationState {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .padding(.trailing, 12)
                }
            }
        }
    }
    
    private var fieldBackground: Color {
        switch validationState {
        case .valid: return Color.white.opacity(0.9)
        case .invalid: return Color.red.opacity(0.05)
        case .none: return Color.white.opacity(0.8)
        }
    }
    
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(borderColor, lineWidth: validationState.isInvalid ? 1.5 : 0)
    }
    
    private var borderColor: Color {
        validationState.isInvalid ? .red.opacity(0.5) : .clear
    }
}

// MARK: - Password Field View
private struct LoginPasswordFieldView: View {
    @Binding var password: String
    let isLoading: Bool
    let onForgotPassword: () -> Void
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PASSWORD")
                .font(.custom("DelaGothicOne-Regular", size: 16))
                .foregroundColor(.black)
            
            ZStack(alignment: .trailing) {
                Group {
                    if isSecure {
                        SecureField("Enter password", text: $password)
                    } else {
                        TextField("Enter password", text: $password)
                    }
                }
                .padding()
                .frame(height: 50)
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
                .font(.body)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.none)
                .disabled(isLoading)
                
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                        .padding(.trailing, 12)
                }
                .disabled(isLoading)
            }
            
            HStack {
                Spacer()
                Button(action: onForgotPassword) {
                    Text("FORGOT PASSWORD?")
                        .font(.custom("DelaGothicOne-Regular", size: 13))
                        .foregroundColor(.gray)
                }
                .disabled(isLoading)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Login Button View
private struct LoginButtonView: View {
    let isLoading: Bool
    let canSubmit: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(canSubmit ? Color.black : Color.gray.opacity(0.3))
                    .frame(height: 50)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("LOG IN")
                        .font(.custom("DelaGothicOne-Regular", size: 18))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(!canSubmit || isLoading)
    }
}

// MARK: - Error Message View
private struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            Text(message)
                .font(.callout)
            Spacer()
            Text("Tap to dismiss")
                .font(.caption2)
                .foregroundColor(.red.opacity(0.7))
        }
        .foregroundColor(.red)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.top, 8)
    }
}

// MARK: - Footer View
private struct LoginFooterView: View {
    var onSignupTapped: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Text("don't have an account?")
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
        .padding(.top, 24)
    }
}

// MARK: - Forgot Password View (Basic Implementation)
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State var email: String
    @State private var isSent = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.none)
                    .padding(.horizontal)
                
                if isSent {
                    Text("✅ Password reset link sent to \(email)")
                        .foregroundColor(.green)
                        .padding()
                }
                
                Button(action: {
                    // TODO: Implement actual password reset
                    withAnimation {
                        isSent = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }) {
                    Text("Send Reset Link")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
