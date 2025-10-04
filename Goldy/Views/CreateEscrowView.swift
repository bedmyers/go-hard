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
                headerSection
                
                primaryActionSection
                
                orDivider
                
                alternativeActionSection
            }
            .padding(24)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.97, green: 0.93, blue: 0.85).ignoresSafeArea())
        .sheet(isPresented: $showFillOut) {
            CreateEscrowFlowView(
                viewModel: viewModel,
                onComplete: onComplete
            )
        }
        .sheet(isPresented: $showUpload) {
            Text("Upload T&C functionality coming soon")
                .padding()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PROTECT A")
                        .font(.custom("DelaGothicOne-Regular", size: 30))
                        .foregroundColor(.black)
                    
                    Text("DEPOSIT")
                        .font(.custom("DelaGothicOne-Regular", size: 30))
                        .foregroundColor(Color("ActiveColor"))
                    
                    Text("Set up escrow protection in 2 minutes")
                        .font(.custom("IBMPlexMono-Regular", size: 14))
                        .foregroundColor(.black)
                        .opacity(0.7)
                        .padding(.top, 4)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private var primaryActionSection: some View {
        Button(action: { showFillOut = true }) {
            HStack(spacing: 20) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("CREATE ESCROW")
                        .font(.custom("DelaGothicOne-Regular", size: 18))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text("Enter vendor details and deposit amount")
                        .font(.custom("IBMPlexMono-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
    
    private var orDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .frame(height: 1)
            
            Text("OR")
                .font(.custom("DaysOne-Regular", size: 11))
                .foregroundColor(.black.opacity(0.4))
            
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
    
    private var alternativeActionSection: some View {
        VStack(spacing: 16) {
            Button(action: { showUpload = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                        .opacity(0.4)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HAVE A CONTRACT?")
                            .font(.custom("DaysOne-Regular", size: 13))
                            .foregroundColor(.black)
                        
                        Text("Upload existing terms & conditions")
                            .font(.custom("IBMPlexMono-Regular", size: 11))
                            .foregroundColor(.black)
                            .opacity(0.6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("SOON")
                        .font(.custom("DelaGothicOne-Regular", size: 9))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(6)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
                .opacity(0.7)
            }
            .disabled(true)
            
            Button(action: { dismiss() }) {
                Text("I'LL DO THIS LATER")
                    .font(.custom("IBMPlexMono-Regular", size: 12))
                    .foregroundColor(.black)
                    .opacity(0.5)
            }
            .padding(.top, 8)
        }
    }
}

#Preview {
    CreateEscrowView(viewModel: EscrowViewModel())
}
