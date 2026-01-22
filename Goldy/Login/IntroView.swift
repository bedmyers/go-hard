//
//  IntroView.swift
//  Goldy
//
//  Created by Blair Myers on 2/26/25.
//

import SwiftUI

// MARK: - IntroView
struct IntroView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var showSignup = false
    @State private var animateTitle = false
    @State private var animateButtons = false
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            VStack {
                FreelanceIntroTitleView(isAnimated: animateTitle)
                
                Spacer()
                
                VStack(spacing: 0) {
                    PrimaryActionButton(title: "GET STARTED") {
                        hapticFeedback()
                        showSignup = true
                    }
                    .padding(.horizontal, 17)
                    .padding(.bottom, 43)
                    
                    IntroLoginOptionView {
                        hapticFeedback()
                        showLogin = true
                    }
                    .padding(.bottom, 144)
                }
                .opacity(animateButtons ? 1 : 0)
                .offset(y: animateButtons ? 0 : 20)
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showSignup) {
            SignupView()
                .environmentObject(appState)
        }
        .onAppear {
            animateContent()
        }
    }
    
    private func animateContent() {
        withAnimation(.easeOut(duration: 0.8)) {
            animateTitle = true
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            animateButtons = true
        }
    }
    
    private func hapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// MARK: - Subviews

private struct IntroTitleView: View {
    let isAnimated: Bool
    @State private var visibleLines: [Bool] = [false, false, false, false, false]
    
    private let lines = ["SAFELY", "HOLD AND", "RELEASE", "YOUR", "PAYMENTS"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<lines.count, id: \.self) { index in
                Text(lines[index])
                    .font(.custom("DelaGothicOne-Regular", size: 45))
                    .foregroundColor(.black)
                    .opacity(visibleLines[index] ? 1 : 0)
                    .offset(x: visibleLines[index] ? 0 : -20)
            }
        }
        .multilineTextAlignment(.leading)
        .padding(.leading, 25)
        .padding(.top, 110)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: isAnimated) { animated in
            if animated {
                animateLines()
            }
        }
    }
    
    private func animateLines() {
        for index in 0..<lines.count {
            withAnimation(.easeOut(duration: 0.4).delay(Double(index) * 0.1)) {
                visibleLines[index] = true
            }
        }
    }
}

private struct IntroLoginOptionView: View {
    let loginAction: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 4) {
            Text("have an account?")
                .font(.custom("DelaGothicOne-Regular", size: 16))
                .foregroundColor(.black)
            
            Button(action: loginAction) {
                Text("log in")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.red)
                    .underline()
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(
                minimumDuration: .infinity,
                maximumDistance: .infinity,
                pressing: { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                },
                perform: {}
            )
        }
    }
}

// MARK: - Alternative Title for Escrow/Freelance Focus

extension IntroView {
    private struct FreelanceIntroTitleView: View {
        let isAnimated: Bool
        @State private var visibleLines: [Bool] = [false, false, false, false, false]
        
        private let lines = ["GET PAID", "SAFELY", "FOR YOUR", "FREELANCE", "WORK"]
        // Alternative: ["SECURE", "PAYMENTS", "FOR EVERY", "FREELANCE", "PROJECT"]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<lines.count, id: \.self) { index in
                    Text(lines[index])
                        .font(.custom("DelaGothicOne-Regular", size: 45))
                        .foregroundColor(.black)
                        .opacity(visibleLines[index] ? 1 : 0)
                        .offset(x: visibleLines[index] ? 0 : -20)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(.leading, 25)
            .padding(.top, 110)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: isAnimated) { animated in
                if animated {
                    animateLines()
                }
            }
        }
        
        private func animateLines() {
            for index in 0..<lines.count {
                withAnimation(.easeOut(duration: 0.4).delay(Double(index) * 0.1)) {
                    visibleLines[index] = true
                }
            }
        }
    }
}

#Preview {
    IntroView()
        .environmentObject(AppState())
}
