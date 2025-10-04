//
//  GetStartedView.swift
//  Goldy
//
//  Created by Blair Myers on 7/8/25.
//

import SwiftUI

struct GetStartedView: View {
    @ObservedObject var viewModel: EscrowViewModel
    @State private var showCreateEscrow = false
    @State private var showJoinEscrow = false
    @State private var showHowItWorks = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                
                if !viewModel.activeEscrows.isEmpty {
                    activeEscrowsSection
                }
                
                mainActionsSection
                howItWorksSection
                bottomSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            .padding(.bottom, 20)
        }
        .background(Color("Background").ignoresSafeArea())
        .sheet(isPresented: $showCreateEscrow) {
            CreateEscrowView(viewModel: viewModel)
        }
        .sheet(isPresented: $showJoinEscrow) {
            JoinEscrowView()
        }
        .sheet(isPresented: $showHowItWorks) {
            HowItWorksView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEDDING")
                .font(.custom("DelaGothicOne-Regular", size: 30))
                .foregroundColor(.black)
            
            Text("DEPOSITS,")
                .font(.custom("DelaGothicOne-Regular", size: 30))
                .foregroundColor(.black)
            
            Text("SECURED")
                .font(.custom("DelaGothicOne-Regular", size: 30))
                .foregroundColor(Color("ActiveColor"))
            
            Text("Protect vendor payments • Get refunds instantly")
                .font(.custom("IBMPlexMono-Regular", size: 13))
                .foregroundColor(.black.opacity(0.6))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    private var activeEscrowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVE PROTECTION")
                .font(.custom("DaysOne-Regular", size: 12))
                .foregroundColor(.black.opacity(0.5))
            
            HStack(spacing: 12) {
                ActiveEscrowCard(
                    vendor: "Sarah Chen Photography",
                    amount: 3500,
                    status: .active
                )
                
                ActiveEscrowCard(
                    vendor: "Rosewood Venue",
                    amount: 8000,
                    status: .pending
                )
            }
            .padding(.bottom, 8)
        }
    }
    
    private var mainActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showCreateEscrow = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 22, weight: .bold))
                            Text("PROTECT A DEPOSIT")
                                .font(.custom("DelaGothicOne-Regular", size: 17))
                        }
                        .foregroundColor(.white)
                        
                        Text("2 minute setup • Vendor gets paid normally")
                            .font(.custom("IBMPlexMono-Regular", size: 11))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(20)
                .background(Color.black)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            
            HStack(spacing: 12) {
                SecondaryButton(
                    title: "I'M A VENDOR",
                    subtitle: "Join escrow",
                    color: Color("ActiveColor")
                ) {
                    showJoinEscrow = true
                }
                
                SecondaryButton(
                    title: "HOW IT WORKS",
                    subtitle: "Learn more",
                    color: Color.yellow.opacity(0.8)
                ) {
                    showHowItWorks = true
                }
            }
        }
    }
    
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HOW IT WORKS")
                .font(.custom("DelaGothicOne-Regular", size: 14))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                StepCard(
                    number: "1",
                    title: "Create Escrow",
                    description: "Enter vendor details and deposit amount"
                )
                
                StepCard(
                    number: "2",
                    title: "Vendor Accepts",
                    description: "They deliver service as agreed"
                )
                
                StepCard(
                    number: "3",
                    title: "Release Payment",
                    description: "Satisfied? Release funds. Problem? Get instant refund"
                )
            }
        }
        .padding(.top, 8)
    }
    
    private var bottomSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.green)
                
                Text("Deposits are securely held in escrows or blockchain smart contracts")
                    .font(.custom("IBMPlexMono-Regular", size: 12))
                    .foregroundColor(.black.opacity(0.7))
                
                Spacer()
            }
            .padding(14)
            .background(Color.green.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
            )
            
            Text("Questions? support@gohard.app")
                .font(.custom("IBMPlexMono-Regular", size: 12))
                .foregroundColor(.black.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }
}

private struct ActiveEscrowCard: View {
    let vendor: String
    let amount: Double
    let status: EscrowStatus
    
    enum EscrowStatus {
        case active, pending
        
        var color: Color {
            switch self {
            case .active: return .green
            case .pending: return .orange
            }
        }
        
        var text: String {
            switch self {
            case .active: return "Active"
            case .pending: return "Pending"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(status.color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 14))
                        .foregroundColor(status.color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(vendor)
                    .font(.custom("DaysOne-Regular", size: 13))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text("$\(amount, specifier: "%.0f")")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.black)
            }
            
            Text(status.text.uppercased())
                .font(.custom("IBMPlexMono-Regular", size: 9))
                .foregroundColor(status.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct SecondaryButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.custom("IBMPlexMono-Regular", size: 10))
                    .foregroundColor(.black.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 2)
            )
        }
    }
}

private struct StepCard: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.1), lineWidth: 2)
                    )
                
                Text(number)
                    .font(.custom("DelaGothicOne-Regular", size: 18))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("IBMPlexMono-Regular", size: 11))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

struct JoinEscrowView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("VENDORS:")
                        .font(.custom("DelaGothicOne-Regular", size: 28))
                        .foregroundColor(.black)
                    
                    Text("JOIN ESCROW")
                        .font(.custom("DelaGothicOne-Regular", size: 28))
                        .foregroundColor(Color("ActiveColor"))
                    
                    Text("Get paid with confidence • Show clients you're professional")
                        .font(.custom("IBMPlexMono-Regular", size: 13))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.bottom, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        BenefitRow(icon: "checkmark.circle.fill", text: "You pay $0 in fees")
                        BenefitRow(icon: "calendar", text: "Get paid faster with milestone releases")
                        BenefitRow(icon: "shield.fill", text: "Protected against payment disputes")
                        BenefitRow(icon: "star.fill", text: "Clients love the security")
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .background(Color("Background"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.green)
            
            Text(text)
                .font(.custom("IBMPlexMono-Regular", size: 13))
                .foregroundColor(.black)
        }
    }
}

struct HowItWorksView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("HOW IT WORKS")
                        .font(.custom("DelaGothicOne-Regular", size: 28))
                        .foregroundColor(.black)
                        .padding(.bottom, 8)
                    
                    DetailedStepCard(
                        number: "1",
                        title: "Create Your Escrow",
                        description: "Enter your vendor's info and the deposit amount. Takes 2 minutes."
                    )
                    
                    DetailedStepCard(
                        number: "2",
                        title: "Vendor Gets Notified",
                        description: "They accept the escrow terms. Funds are held securely until delivery."
                    )
                    
                    DetailedStepCard(
                        number: "3",
                        title: "Service Gets Delivered",
                        description: "Your vendor completes the work as agreed."
                    )
                    
                    DetailedStepCard(
                        number: "4",
                        title: "You Release Payment",
                        description: "Happy? Release the funds with one tap. Problem? Get instant refund."
                    )
                    
                    Spacer()
                }
                .padding(20)
            }
            .background(Color("Background"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DetailedStepCard: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: 44, height: 44)
                
                Text(number)
                    .font(.custom("DelaGothicOne-Regular", size: 20))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom("DaysOne-Regular", size: 16))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("IBMPlexMono-Regular", size: 13))
                    .foregroundColor(.black.opacity(0.6))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

extension EscrowViewModel {
    var activeEscrows: [Any] {
        []
    }
}

#Preview {
    GetStartedView(viewModel: EscrowViewModel())
}
