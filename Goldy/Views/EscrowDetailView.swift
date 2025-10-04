//
//  EscrowDetailView.swift
//  Goldy
//
//  Created by Blair Myers on 4/16/25.
//

import SwiftUI

struct EscrowDetailView: View {
    let escrowId: Int
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("authToken") private var authToken = ""
    
    @State private var dto: EscrowDTO?
    @State private var escrow: EscrowDetail?
    @State private var isLoading = false
    @State private var errorText = ""
    @State private var showFundSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let escrow {
                    VStack(alignment: .leading, spacing: 28) {
                        headerSection(escrow)
                        
                        statusSection
                        
                        purposeSection(escrow)
                        
                        progressOverviewSection(escrow)
                        
                        milestonesSection(escrow)
                        
                        financialSummarySection(escrow)
                        
                        cancellationSection(escrow)
                        
                        signatoriesSection(escrow)
                        
                        actionsSection
                    }
                    .padding(24)
                } else if isLoading {
                    loadingView
                } else if !errorText.isEmpty {
                    errorView
                }
            }
            .background(Color(red: 0.97, green: 0.93, blue: 0.85).ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onAppear { Task { await reload() } }
        .sheet(isPresented: $showFundSheet, onDismiss: {
            Task { await reload() }
        }) {
            FundEscrowView(escrowId: escrowId)
        }
    }
    
    // MARK: - View Components
    
    private func headerSection(_ escrow: EscrowDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(escrow.title)
                    .font(.custom("DelaGothicOne-Regular", size: 30))
                    .foregroundColor(.black)
                
                if let subtitle = escrow.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.custom("DaysOne-Regular", size: 16))
                        .foregroundColor(.black)
                        .opacity(0.6)
                }
            }
        }
    }
    
    private var statusSection: some View {
        HStack(spacing: 16) {
            StatusBadge(status: dto?.status ?? "UNKNOWN")
            
            Spacer()
            
            if dto?.status == "PENDING" {
                Button(action: { showFundSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 14))
                        Text("FUND ESCROW")
                            .font(.custom("DelaGothicOne-Regular", size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func purposeSection(_ escrow: EscrowDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(text: "PURPOSE OF THE ESCROW")
            
            Text(escrow.purpose ?? "No purpose specified")
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .foregroundColor(.black)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private func progressOverviewSection(_ escrow: EscrowDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(text: "PROGRESS OVERVIEW")
            
            VStack(spacing: 16) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color("ActiveColor"))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.7))
                            .frame(width: geometry.size.width * escrow.progress, height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("\(Int(escrow.progress * 100))% COMPLETE")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.0f", escrow.totalReleased)) released")
                        .font(.custom("DaysOne-Regular", size: 12))
                        .foregroundColor(.black)
                        .opacity(0.7)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private func milestonesSection(_ escrow: EscrowDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(text: "MILESTONES")
            
            VStack(spacing: 12) {
                ForEach(escrow.milestones) { milestone in
                    MilestoneCard(
                        milestone: milestone,
                        canRelease: dto?.status == "AUTHORIZED" && !milestone.released,
                        onRelease: { release(milestoneId: milestone.id) }
                    )
                }
            }
        }
    }
    
    private func financialSummarySection(_ escrow: EscrowDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(text: "FINANCIAL SUMMARY")
            
            VStack(spacing: 16) {
                FinancialRow(
                    title: "TOTAL COMMITTED",
                    amount: escrow.totalCommitted,
                    isTotal: true
                )
                
                FinancialRow(
                    title: "TOTAL RELEASED",
                    amount: escrow.totalReleased,
                    color: .green
                )
                
                FinancialRow(
                    title: "REMAINING IN ESCROW",
                    amount: escrow.totalCommitted - escrow.totalReleased,
                    color: .orange
                )
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private func cancellationSection(_ escrow: EscrowDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(text: "CANCELLATION & REFUND POLICY")
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(escrow.cancellationPolicy, id: \.self) { policy in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(policy)
                            .font(.custom("IBMPlexMono-Regular", size: 14))
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private func signatoriesSection(_ escrow: EscrowDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(text: "SIGNATORIES")
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ForEach(escrow.signerImageNames, id: \.self) { imageName in
                        Circle()
                            .fill(Color("ActiveColor"))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            )
                    }
                    
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EXECUTED ON")
                            .font(.custom("DelaGothicOne-Regular", size: 12))
                            .foregroundColor(.black)
                            .opacity(0.6)
                        
                        Text(escrow.signDate, format: .dateTime.day().month().year())
                            .font(.custom("DaysOne-Regular", size: 14))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {}) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                    Text("VIEW TERMS AND CONDITIONS")
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black)
                .cornerRadius(12)
            }
            
            Button(action: {}) {
                HStack(spacing: 12) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 16))
                    Text("MESSAGE OTHER PARTY")
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.black)
            
            Text("Loading escrow details...")
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .foregroundColor(.black)
                .opacity(0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
                .opacity(0.6)
            
            Text(errorText)
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Retry") {
                Task { await reload() }
            }
            .font(.custom("DelaGothicOne-Regular", size: 14))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Supporting Views
    
    private struct SectionHeader: View {
        let text: String
        
        var body: some View {
            Text(text)
                .font(.custom("DelaGothicOne-Regular", size: 16))
                .foregroundColor(.black)
        }
    }
    
    private struct StatusBadge: View {
        let status: String
        
        var body: some View {
            Text(status.capitalized)
                .font(.custom("DelaGothicOne-Regular", size: 12))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor)
                .cornerRadius(20)
        }
        
        private var statusColor: Color {
            switch status.uppercased() {
            case "PENDING":
                return Color.yellow.opacity(0.8)
            case "AUTHORIZED", "ACTIVE":
                return Color.blue.opacity(0.3)
            case "COMPLETED":
                return Color.green.opacity(0.3)
            default:
                return Color.gray.opacity(0.3)
            }
        }
    }
    
    private struct MilestoneCard: View {
        let milestone: Milestone
        let canRelease: Bool
        let onRelease: () -> Void
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MILESTONE \(milestone.id)")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.black)
                    
                    if milestone.released {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 14))
                            
                            Text("RELEASED")
                                .font(.custom("DaysOne-Regular", size: 12))
                                .foregroundColor(.green)
                        }
                    } else if canRelease {
                        Button(action: onRelease) {
                            Text("RELEASE")
                                .font(.custom("DelaGothicOne-Regular", size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black)
                                .cornerRadius(8)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            
                            Text("LOCKED")
                                .font(.custom("DaysOne-Regular", size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Text("$\(String(format: "%.0f", milestone.amount))")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.8))
                    .cornerRadius(8)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private struct FinancialRow: View {
        let title: String
        let amount: Double
        var isTotal: Bool = false
        var color: Color = .black
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.custom(isTotal ? "DelaGothicOne-Regular" : "DaysOne-Regular", size: isTotal ? 16 : 14))
                    .foregroundColor(.black)
                    .opacity(isTotal ? 1.0 : 0.8)
                
                Spacer()
                
                Text("$\(String(format: "%.0f", amount))")
                    .font(.custom("DelaGothicOne-Regular", size: isTotal ? 20 : 16))
                    .foregroundColor(color)
                    .bold()
            }
        }
    }
    
    // MARK: - Networking
    
    private func reload() async {
        guard !authToken.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let all = try await EscrowService.myEscrows(token: authToken)
            if let found = all.first(where: { $0.id == escrowId }) {
                self.dto = found
                self.escrow = found.toDetail()
                self.errorText = ""
            } else {
                self.errorText = "Escrow not found."
            }
        } catch {
            self.errorText = "Failed to load escrow: \(error.localizedDescription)"
        }
    }
    
    private func release(milestoneId: Int) {
        guard !authToken.isEmpty else { return }
        Task {
            do {
                _ = try await EscrowService.release(
                    escrowId: escrowId,
                    milestoneId: milestoneId,
                    token: authToken
                )
                await reload()
            } catch {
                self.errorText = "Release failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview

struct EscrowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EscrowDetailView(escrowId: 1)
    }
}
