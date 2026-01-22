//
//  VendorMyBidsView.swift
//  Goldy
//
//  Created by Blair Myers on 11/30/25.
//

import SwiftUI

struct VendorMyBidsView: View {
    @State private var bids: [Bid] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else if bids.isEmpty {
                emptyState
            } else {
                bidsList
            }
        }
        .navigationTitle("My Bids")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadBids()
        }
        .refreshable {
            await loadBids()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "paperplane")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Bids Yet")
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text("Browse open requests and submit bids to get started")
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: VendorRFPBrowseView()) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("FIND WORK")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(hex: "FFD700"))
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Bids List
    
    private var bidsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats summary
                bidStats
                    .padding(.horizontal)
                
                LazyVStack(spacing: 16) {
                    ForEach(bids) { bid in
                        MyBidCard(bid: bid)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Bid Stats
    
    private var bidStats: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(bids.count)",
                label: "Total Bids",
                color: Color(hex: "3B82F6")
            )
            
            StatCard(
                value: "\(bids.filter { $0.status == .submitted }.count)",
                label: "Pending",
                color: Color(hex: "F59E0B")
            )
            
            StatCard(
                value: "\(bids.filter { $0.status == .accepted }.count)",
                label: "Accepted",
                color: Color(hex: "22C55E")
            )
        }
    }
    
    // MARK: - Load Bids
    
    private func loadBids() async {
        do {
            bids = try await APIService.shared.getMyBids()
            print("✅ Loaded \(bids.count) bids")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading bids: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("DelaGothicOne-Regular", size: 24))
                .foregroundColor(color)
            Text(label)
                .font(.custom("Spectral-Medium", size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - My Bid Card

private struct MyBidCard: View {
    let bid: Bid
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let rfp = bid.rfp {
                        Text(rfp.title)
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                    } else {
                        Text("Request #\(bid.rfpId)")
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                    }
                    
                    Text("Submitted \(bid.createdAt.timeAgoDisplay())")
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                BidStatusBadge(status: bid.status)
            }
            
            // Your bid amount
            HStack {
                Text("Your bid:")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                Text(bid.amountFormatted)
                    .font(.custom("DelaGothicOne-Regular", size: 18))
                    .foregroundColor(Color(hex: "22C55E"))
            }
            
            // Proposal preview
            Text(bid.proposal)
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .lineLimit(2)
            
            // Status message
            statusMessage
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusBorderColor, lineWidth: bid.status == .accepted ? 2 : 0)
        )
    }
    
    @ViewBuilder
    private var statusMessage: some View {
        switch bid.status {
        case .submitted:
            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text("Waiting for client response")
            }
            .font(.custom("Spectral-Regular", size: 12))
            .foregroundColor(Color(hex: "F59E0B"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "F59E0B").opacity(0.1))
            .cornerRadius(8)
            
        case .accepted:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                Text("Congratulations! Your bid was accepted")
            }
            .font(.custom("Spectral-Regular", size: 12))
            .foregroundColor(Color(hex: "22C55E"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "22C55E").opacity(0.1))
            .cornerRadius(8)
            
        case .rejected:
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                Text("Bid was not selected")
            }
            .font(.custom("Spectral-Regular", size: 12))
            .foregroundColor(.gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var statusBorderColor: Color {
        switch bid.status {
        case .accepted: return Color(hex: "22C55E")
        case .submitted: return .clear
        case .rejected: return .clear
        }
    }
}

// MARK: - Bid Status Badge

private struct BidStatusBadge: View {
    let status: Bid.BidStatus
    
    var body: some View {
        Text(displayText)
            .font(.custom("Spectral-Bold", size: 10))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(12)
    }
    
    private var displayText: String {
        switch status {
        case .submitted: return "PENDING"
        case .accepted: return "ACCEPTED"
        case .rejected: return "DECLINED"
        }
    }
    
    private var color: Color {
        switch status {
        case .submitted: return Color(hex: "F59E0B")
        case .accepted: return Color(hex: "22C55E")
        case .rejected: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VendorMyBidsView()
    }
}
