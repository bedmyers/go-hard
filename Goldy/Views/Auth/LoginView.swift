//
//  LoginView.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI
import AuthenticationServices

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
                let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
                let name = UserDefaults.standard.string(forKey: "userName") ?? ""
                let userType = UserDefaults.standard.string(forKey: "userType") ?? "CUSTOMER"
                
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                print("DEBUG: LoginView calling appState.login")
                appState.login(token: token, userId: userId, email: email, name: name, userType: userType)
                
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

            // Divider
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 24)

            // Apple Sign In Button
            AppleSignInButton(authVM: authVM)

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

// MARK: - Apple Sign In Button
private struct AppleSignInButton: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            switch result {
            case .success(let authResults):
                handleAppleSignIn(authResults)
            case .failure(let error):
                print("Apple Sign In failed: \(error)")
                authVM.errorMessage = "Apple Sign In failed. Please try again."
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(8)
    }

    private func handleAppleSignIn(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            authVM.errorMessage = "Failed to get Apple credentials"
            return
        }

        // Get user info (only available on first sign in)
        var userInfo: [String: Any] = [:]
        if let email = appleIDCredential.email {
            userInfo["email"] = email
        }
        if let fullName = appleIDCredential.fullName {
            userInfo["name"] = [
                "firstName": fullName.givenName ?? "",
                "lastName": fullName.familyName ?? ""
            ]
        }

        // Send to backend
        Task {
            await signInWithApple(identityToken: identityToken, userInfo: userInfo)
        }
    }

    private func signInWithApple(identityToken: String, userInfo: [String: Any]) async {
        authVM.isLoading = true
        authVM.errorMessage = ""

        guard let url = URL(string: "https://go-hard-backend-production.up.railway.app/auth/apple") else {
            authVM.errorMessage = "Invalid server URL"
            authVM.isLoading = false
            return
        }

        var body: [String: Any] = ["identityToken": identityToken]
        if !userInfo.isEmpty {
            body["user"] = userInfo
        }

        guard let requestBody = try? JSONSerialization.data(withJSONObject: body) else {
            authVM.errorMessage = "Failed to prepare request"
            authVM.isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let decoder = JSONDecoder()
                let loginResponse = try decoder.decode(LoginResponse.self, from: data)

                await MainActor.run {
                    // Store credentials
                    UserDefaults.standard.set(loginResponse.token, forKey: "authToken")
                    UserDefaults.standard.set(loginResponse.user.id, forKey: "userId")
                    UserDefaults.standard.set(loginResponse.user.email, forKey: "userEmail")
                    UserDefaults.standard.set(loginResponse.user.name, forKey: "userName")
                    UserDefaults.standard.set(loginResponse.user.userType, forKey: "userType")

                    authVM.isLoading = false
                    authVM.isAuthenticated = true

                    print("✅ Apple Sign In successful: \(loginResponse.user.email)")
                }
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Apple Sign In error: \(errorBody)")
                await MainActor.run {
                    authVM.errorMessage = "Sign in failed. Please try again."
                    authVM.isLoading = false
                }
            }
        } catch {
            print("Apple Sign In network error: \(error)")
            await MainActor.run {
                authVM.errorMessage = "Network error. Please try again."
                authVM.isLoading = false
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
