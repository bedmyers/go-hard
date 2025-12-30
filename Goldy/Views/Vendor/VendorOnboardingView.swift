//
//  VendorOnboardingView.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI
import SafariServices

struct VendorOnboardingView: View {
    @StateObject private var viewModel = VendorOnboardingViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                    } else if let error = viewModel.errorMessage {
                        ErrorView(message: error) {
                            Task { await viewModel.checkStatus() }
                        }
                    } else if viewModel.needsOnboarding {
                        OnboardingNeededView(viewModel: viewModel)
                    } else {
                        ConnectedView(viewModel: viewModel)
                    }
                }
                .padding()
            }
            .navigationTitle("Bank Account")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.checkStatus()
            }
            .sheet(isPresented: $viewModel.showingOnboarding) {
                if let url = viewModel.onboardingURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                        .onDisappear {
                            Task {
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                await viewModel.checkStatus()
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Onboarding Needed View
private struct OnboardingNeededView: View {
    @ObservedObject var viewModel: VendorOnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "dollarsign.circle.fill")
                .font(.custom("Spectral-Light", size: 80))
                .foregroundColor(Color(hex: "22C55E"))
            
            // Title & subtitle
            VStack(spacing: 12) {
                Text("CONNECT YOUR\nBANK ACCOUNT")
                    .font(.custom("DelaGothicOne-Regular", size: 28))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("Get paid directly by Stripe in 2 business days")
                    .font(.custom("Spectral-Regular", size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Info cards
            VStack(spacing: 12) {
                InfoCard(
                    icon: "checkmark.shield.fill",
                    text: "Secure payment processing by Stripe",
                    color: Color(hex: "BBF7D0")
                )
                
                InfoCard(
                    icon: "clock.fill",
                    text: "Funds available in 2 business days",
                    color: Color(hex: "DBEAFE")
                )
                
                InfoCard(
                    icon: "lock.fill",
                    text: "Bank-level security & encryption",
                    color: Color(hex: "E9D5FF")
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // CTA
            Button {
                Task { await viewModel.startOnboarding() }
            } label: {
                Text("CONNECT WITH STRIPE")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.black)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// MARK: - Connected View
private struct ConnectedView: View {
    @ObservedObject var viewModel: VendorOnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.custom("Spectral-Light", size: 80))
                .foregroundColor(Color(hex: "22C55E"))
            
            VStack(spacing: 12) {
                Text("BANK ACCOUNT\nCONNECTED")
                    .font(.custom("DelaGothicOne-Regular", size: 28))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("You're ready to receive payments!")
                    .font(.custom("Spectral-Regular", size: 15))
                    .foregroundColor(.gray)
            }
            
            if let accountId = viewModel.status?.accountId {
                Text("Account: \(String(accountId.suffix(8)))")
                    .font(.custom("Spectral-Medium", size: 12))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Button {
                Task { await viewModel.openDashboard() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                    Text("VIEW STRIPE DASHBOARD")
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(hex: "7C3AED"))
                .cornerRadius(12)
                .shadow(color: Color(hex: "7C3AED").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// MARK: - Info Card
private struct InfoCard: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.custom("Spectral-Medium", size: 20))
                .foregroundColor(.black)
            
            Text(text)
                .font(.custom("Spectral-Medium", size: 14))
                .foregroundColor(.black)
            
            Spacer()
        }
        .padding(16)
        .background(color)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Error View
private struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.custom("Spectral-Light", size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("SOMETHING WENT WRONG")
                    .font(.custom("DelaGothicOne-Regular", size: 20))
                
                Text(message)
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                retryAction()
            } label: {
                Text("TRY AGAIN")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Safari View
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredControlTintColor = .black
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    VendorOnboardingView()
}
