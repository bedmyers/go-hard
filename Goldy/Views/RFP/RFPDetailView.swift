//
//  RFPDetailView.swift
//  Goldy
//
//  Created by Blair Myers on 11/28/25.
//
import SwiftUI

struct RFPDetailView: View {
    @StateObject private var viewModel: RFPDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    init(rfp: RFP) {
        _viewModel = StateObject(wrappedValue: RFPDetailViewModel(rfp: rfp))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                rfpHeader
                
                rfpDetails
                
                bidsSection
                
                if viewModel.rfp.isOpen {
                    closeRequestButton
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color("Background"))
        .navigationTitle("Request Details")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refresh()
        }
        .alert("Accept Bid", isPresented: $viewModel.showAcceptConfirm, presenting: viewModel.selectedBid) { bid in
            Button("Accept", role: .none) {
                Task { await viewModel.acceptBid(bid) }
            }
            Button("Cancel", role: .cancel) { }
        } message: { bid in
            Text("Accept \(bid.vendor?.name ?? "this vendor")'s bid for \(bid.amountFormatted)?")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong")
        }
    }
    
    // MARK: - Header
    
    private var rfpHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FFD700").opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "megaphone.fill")
                    .font(.custom("Spectral-Regular", size: 32))
                    .foregroundColor(Color(hex: "FFD700"))
            }
            
            VStack(spacing: 6) {
                Text(viewModel.rfp.title)
                    .font(.custom("DelaGothicOne-Regular", size: 22))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.custom("Spectral-Medium", size: 12))
                        .foregroundColor(statusColor)
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch viewModel.rfp.status {
        case .open: return Color(hex: "22C55E")
        case .closed: return .gray
        case .awarded: return Color(hex: "3B82F6")
        }
    }
    
    private var statusText: String {
        switch viewModel.rfp.status {
        case .open: return "ACTIVE"
        case .closed: return "CLOSED"
        case .awarded: return "AWARDED"
        }
    }
    
    // MARK: - Details
    
    private var rfpDetails: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.custom("Spectral-Bold", size: 12))
                    .foregroundColor(.gray)
                
                Text(viewModel.rfp.description)
                    .font(.custom("Spectral-Regular", size: 15))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            
            HStack(spacing: 16) {
                DetailCard(
                    icon: "dollarsign.circle.fill",
                    title: "Budget",
                    value: viewModel.rfp.budgetFormatted
                )
                
                if let deadline = viewModel.rfp.deadline {
                    DetailCard(
                        icon: "calendar",
                        title: "Deadline",
                        value: deadline.formatted(date: .abbreviated, time: .omitted)
                    )
                }
            }
        }
    }
    
    // MARK: - Bids Section
    
    private var bidsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Bids")
                    .font(.custom("DelaGothicOne-Regular", size: 18))
                
                Spacer()
                
                Text("\(viewModel.rfp.bidCount)")
                    .font(.custom("Spectral-Bold", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "22C55E"))
                    .cornerRadius(12)
            }
            
            if let bids = viewModel.rfp.bids, !bids.isEmpty {
                VStack(spacing: 12) {
                    ForEach(bids) { bid in
                        BidCard(bid: bid, isRFPOpen: viewModel.rfp.isOpen) {
                            viewModel.selectedBid = bid
                            viewModel.showAcceptConfirm = true
                        } onDecline: {
                            Task {
                                _ = try? await APIService.shared.rejectBid(bidId: bid.id)
                                await viewModel.refresh()
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.open")
                        .font(.custom("Spectral-Regular", size: 40))
                        .foregroundColor(.gray.opacity(0.4))
                    
                    Text("No bids yet")
                        .font(.custom("Spectral-Medium", size: 15))
                        .foregroundColor(.gray)
                    
                    Text("Vendors will submit bids here")
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Close Request Button
    
    private var closeRequestButton: some View {
        Button {
            Task { await viewModel.closeRFP() }
        } label: {
            Text("Close Request")
                .font(.custom("Spectral-Medium", size: 14))
                .foregroundColor(.red)
        }
        .padding(.top, 8)
    }
}

// MARK: - Detail Card

private struct DetailCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.gray)
                Text(title)
                    .font(.custom("Spectral-Medium", size: 11))
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.custom("Spectral-Bold", size: 15))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Bid Card

struct BidCard: View {
    let bid: Bid
    let isRFPOpen: Bool
    var onAccept: () -> Void
    var onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: "E5E7EB"))
                        .frame(width: 44, height: 44)
                    
                    Text(initials)
                        .font(.custom("Spectral-Bold", size: 14))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(bid.vendor?.name ?? "Vendor")
                        .font(.custom("Spectral-Bold", size: 15))
                    
                    if let email = bid.vendor?.email {
                        Text(email)
                            .font(.custom("Spectral-Regular", size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(bid.amountFormatted)
                        .font(.custom("DelaGothicOne-Regular", size: 18))
                    
                    BidStatusBadge(status: bid.status)
                }
            }
            
            Text(bid.proposal)
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
            
            if bid.isSubmitted && isRFPOpen {
                HStack(spacing: 12) {
                    Button {
                        onAccept()
                    } label: {
                        Text("ACCEPT")
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "22C55E"))
                            .cornerRadius(8)
                    }
                    
                    Button {
                        onDecline()
                    } label: {
                        Text("DECLINE")
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    private var initials: String {
        guard let name = bid.vendor?.name else { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Bid Status Badge

private struct BidStatusBadge: View {
    let status: Bid.BidStatus
    
    var body: some View {
        Text(displayText)
            .font(.custom("Spectral-Bold", size: 9))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
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
        case .rejected: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RFPDetailView(rfp: RFP(
            id: 1,
            projectId: 1,
            customerId: 1,
            title: "Wedding Photographer Needed",
            description: "Looking for an experienced wedding photographer for our June 2025 wedding.",
            budget: 500000,
            deadline: Date().addingTimeInterval(86400 * 14),
            status: .open,
            eventDate: Date().addingTimeInterval(86400 * 180),
            location: "Detroit, MI",
            guestCount: 150,
            inspirationUrl: nil,
            styleTags: ["natural-light", "romantic"],
            mustHaves: ["Available on date", "Second shooter"],
            niceToHaves: ["Drone footage"],
            decisionDate: Date().addingTimeInterval(86400 * 21),
            visibility: .public,
            invitedVendorIds: nil,
            bids: [],
            customer: nil,
            project: nil,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
