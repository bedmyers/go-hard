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
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SignupViewModel()
    @FocusState private var focusedField: SignupField?
    @Environment(\.dismiss) private var dismiss
    
    enum SignupField {
        case email, name, password
    }
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            ScrollView {
                SignupMainContentView(
                    viewModel: viewModel,
                    focusedField: $focusedField,
                    onLogin: { dismiss() }
                )
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onChange(of: viewModel.isSignedUp) { isSignedUp in
            if isSignedUp {
                let token = UserDefaults.standard.string(forKey: "authToken") ?? ""
                let userId = UserDefaults.standard.integer(forKey: "userId")
                
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                print("DEBUG: SignupView calling appState.login with userId: \(userId)")
                appState.login(token: token, userId: userId)
                
                dismiss()  // Close signup view after successful registration
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

// MARK: - Main Content View
private struct SignupMainContentView: View {
    @ObservedObject var viewModel: SignupViewModel
    @FocusState.Binding var focusedField: SignupView.SignupField?
    let onLogin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignupTitleView()
            
            SignupEmailFieldView(
                email: $viewModel.email,
                validationState: viewModel.emailValidationState,
                isLoading: viewModel.isLoading
            )
            .focused($focusedField, equals: .email)
            .onSubmit { focusedField = .name }
            .padding(.bottom, 16)
            
            SignupNameFieldView(
                name: $viewModel.name,
                validationState: viewModel.nameValidationState,
                isLoading: viewModel.isLoading
            )
            .focused($focusedField, equals: .name)
            .onSubmit { focusedField = .password }
            .padding(.bottom, 16)
            
            SignupPasswordFieldView(
                password: $viewModel.password,
                validationState: viewModel.passwordValidationState,
                isLoading: viewModel.isLoading
            )
            .focused($focusedField, equals: .password)
            .onSubmit {
                if viewModel.canSubmit {
                    viewModel.signUp()
                    focusedField = nil
                }
            }
            .padding(.bottom, 24)
            
            PasswordRequirementsView(password: viewModel.password)
                .padding(.bottom, 24)
            
            SignupButtonView(
                isLoading: viewModel.isLoading,
                canSubmit: viewModel.canSubmit,
                action: {
                    focusedField = nil
                    viewModel.signUp()
                }
            )
            
            // Error message
            if !viewModel.errorMessage.isEmpty {
                ErrorMessageView(message: viewModel.errorMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture {
                        viewModel.clearError()
                    }
            }
            
            SignupLoginLinkView(onLogin: onLogin)
            
            Spacer(minLength: 40)
            
            SignupFooterView()
        }
        .padding(.horizontal, 15)
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
    }
}

// MARK: - Title View
private struct SignupTitleView: View {
    var body: some View {
        Text("SIGN UP")
            .font(.custom("DelaGothicOne-Regular", size: 30))
            .padding(.top, 100)
            .padding(.bottom, 40)
    }
}

// MARK: - Email Field View
private struct SignupEmailFieldView: View {
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

// MARK: - Name Field View
private struct SignupNameFieldView: View {
    @Binding var name: String
    let validationState: ValidationState
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("NAME")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.black)
                
                if case .invalid(let message) = validationState {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            ZStack(alignment: .trailing) {
                TextField("Enter name", text: $name)
                    .padding()
                    .frame(height: 50)
                    .background(fieldBackground)
                    .cornerRadius(8)
                    .overlay(fieldBorder)
                    .font(.body)
                    .autocorrectionDisabled(true)
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
private struct SignupPasswordFieldView: View {
    @Binding var password: String
    let validationState: ValidationState
    let isLoading: Bool
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PASSWORD")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.black)
                
                if case .invalid(let message) = validationState {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
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
                .background(fieldBackground)
                .cornerRadius(8)
                .overlay(fieldBorder)
                .font(.body)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.none)
                .disabled(isLoading)
                
                HStack(spacing: 8) {
                    if case .valid = validationState {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Button(action: { isSecure.toggle() }) {
                        Image(systemName: isSecure ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .disabled(isLoading)
                }
                .padding(.trailing, 12)
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

// MARK: - Password Requirements View
private struct PasswordRequirementsView: View {
    let password: String
    
    private var requirements: [(text: String, met: Bool)] {
        [
            ("At least 8 characters", password.count >= 8),
            ("Contains uppercase letter", password.contains(where: { $0.isUppercase })),
            ("Contains lowercase letter", password.contains(where: { $0.isLowercase })),
            ("Contains number", password.contains(where: { $0.isNumber }))
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(requirements, id: \.text) { requirement in
                HStack(spacing: 6) {
                    Image(systemName: requirement.met ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(requirement.met ? .green : .gray)
                    
                    Text(requirement.text)
                        .font(.caption)
                        .foregroundColor(requirement.met ? .gray : .gray.opacity(0.7))
                }
            }
        }
        .opacity(password.isEmpty ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: password.isEmpty)
    }
}

// MARK: - Sign Up Button View
private struct SignupButtonView: View {
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
                    Text("SIGN UP")
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

// MARK: - Login Link View
private struct SignupLoginLinkView: View {
    let onLogin: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Text("have an account?")
                .foregroundColor(.black)
            Button(action: onLogin) {
                Text("log in")
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

// MARK: - Footer View
private struct SignupFooterView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("By signing up you agree to our")
                .foregroundColor(.gray)
                .font(.custom("DelaGothicOne-Regular", size: 10))
            
            HStack(spacing: 4) {
                Button(action: {
                    if let url = URL(string: "https://yourapp.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Terms of Use")
                        .foregroundColor(.gray)
                        .underline()
                        .font(.custom("DelaGothicOne-Regular", size: 10))
                }
                
                Text("and our")
                    .foregroundColor(.gray)
                    .font(.custom("DelaGothicOne-Regular", size: 10))
                
                Button(action: {
                    if let url = URL(string: "https://yourapp.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Privacy Policy")
                        .foregroundColor(.gray)
                        .underline()
                        .font(.custom("DelaGothicOne-Regular", size: 10))
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding(.bottom, 40)
    }
}
