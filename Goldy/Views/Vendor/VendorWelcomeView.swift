//
//  VendorWelcomeView.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI

struct VendorWelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    let onSetupProfile: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 24) {
                            Spacer(minLength: 40)
                            
                            // Welcome header
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.custom("Spectral-Light", size: 64))
                                    .foregroundColor(Color(hex: "7C3AED"))
                                
                                Text("WELCOME TO\nGO HARD")
                                    .font(.custom("DelaGothicOne-Regular", size: 28))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                                
                                Text("Find clients, manage projects, and get paid securely")
                                    .font(.custom("Spectral-Regular", size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            
                            // Benefits cards
                            VStack(spacing: 12) {
                                BenefitCard(
                                    icon: "doc.text.magnifyingglass",
                                    title: "Bid on Projects",
                                    description: "Browse RFPs and submit competitive proposals",
                                    color: Color(hex: "E9D5FF")
                                )
                                
                                BenefitCard(
                                    icon: "shippingbox.fill",
                                    title: "Secure Escrow",
                                    description: "Every payment protected until work is approved",
                                    color: Color(hex: "BBF7D0")
                                )
                                
                                BenefitCard(
                                    icon: "photo.stack",
                                    title: "Build Portfolio",
                                    description: "Showcase your work and win more clients",
                                    color: Color(hex: "FED7AA")
                                )
                            }
                            .padding(.horizontal, 24)
                            
                            // Extra space at bottom for pinned buttons
                            Spacer(minLength: 120)
                        }
                    }
                    
                    // Pinned CTAs at bottom
                    VStack(spacing: 12) {
                        Button {
                            onSetupProfile()
                        } label: {
                            Text("SET UP YOUR PROFILE")
                                .font(.custom("DelaGothicOne-Regular", size: 15))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("I'll do this later")
                                .font(.custom("Spectral-Medium", size: 14))
                                .foregroundColor(.gray)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)  // Extra bottom padding for safe area
                    .background(
                        Color("Background")
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                    )
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Benefit Card
private struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.custom("Spectral-Light", size: 24))
                .foregroundColor(.black)
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("DelaGothicOne-Regular", size: 15))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(color)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VendorWelcomeView(onSetupProfile: {})
}
