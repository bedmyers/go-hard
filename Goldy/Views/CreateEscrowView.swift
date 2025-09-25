//
//  CreateEscrowView.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI

struct CreateEscrowView: View {
    var viewModel: EscrowViewModel
    var onComplete: (() -> Void)? = nil

    @State private var showFillOut = false
    @State private var showUpload = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Main Action Cards
                actionCardsSection
                
                // Alternative Action
                alternativeActionSection
            }
            .padding(24)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.97, green: 0.93, blue: 0.85).ignoresSafeArea())
        .sheet(isPresented: $showFillOut) {
            FillOutEscrowView(
                viewModel: viewModel,
                onComplete: onComplete,
                escrowName: "",
                parties: []
            )
        }
        .sheet(isPresented: $showUpload) {
            Text("Upload T&C functionality coming soon")
                .padding()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CREATE AN \n ESCROW")
                        .font(.custom("DelaGothicOne-Regular", size: 30))
                        .foregroundColor(.black)
                    
                    Text("Choose how you'd like to set up your escrow agreement")
                        .font(.custom("IBMPlexMono-Regular", size: 14))
                        .foregroundColor(.black)
                        .opacity(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    private var actionCardsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("ADD TERMS & CONDITIONS")
                .font(.custom("DelaGothicOne-Regular", size: 16))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                // Upload terms card
                ActionCard(
                    icon: "doc.badge.plus",
                    title: "UPLOAD EXISTING TERMS",
                    subtitle: "Import your T&C document",
                    isDisabled: true,
                    action: { showUpload = true }
                )
                
                // Manual creation card
                ActionCard(
                    icon: "doc.text.fill",
                    title: "CREATE FROM SCRATCH",
                    subtitle: "Build your escrow step by step",
                    action: { showFillOut = true }
                )
            }
        }
    }
    
    private var alternativeActionSection: some View {
        VStack(spacing: 12) {
            Button(action: {}) {
                Text("SAVE FOR LATER")
                    .font(.custom("DelaGothicOne-Regular", size: 12))
                    .foregroundColor(.black)
                    .underline()
            }
        }
    }
}

// MARK: - Supporting Views

private struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon section
                VStack {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.black)
                        .opacity(isDisabled ? 0.4 : 1.0)
                    
                    if isDisabled {
                        Text("SOON")
                            .font(.custom("DelaGothicOne-Regular", size: 8))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }
                }
                .frame(width: 60)
                
                // Content section
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("DelaGothicOne-Regular", size: 18))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.custom("IBMPlexMono-Regular", size: 14))
                        .foregroundColor(.black)
                        .opacity(0.7)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .opacity(0.6)
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(Color("ActiveColor"))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            .opacity(isDisabled ? 0.7 : 1.0)
        }
        .disabled(isDisabled)
    }
}

#Preview {
    CreateEscrowView(viewModel: EscrowViewModel())
}
