//
//  RFPListView.swift
//  Goldy
//
//  Created by Blair Myers on 11/28/25.
//

import SwiftUI

struct RFPListView: View {
    @StateObject private var viewModel = RFPListViewModel()
    @State private var showCreateRFP = false
    @State private var expandedRFPId: Int?
    
    let projectId: Int
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.rfps.isEmpty {
                ProgressView()
            } else if viewModel.rfps.isEmpty {
                emptyState
            } else {
                rfpList
            }
        }
        .navigationTitle("My RFPs")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateRFP = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("New RFP")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                }
            }
        }
        .sheet(isPresented: $showCreateRFP) {
            CreateRFPView(projectId: projectId) { _ in
                Task { await viewModel.loadRFPs(projectId: projectId) }
            }
        }
        .refreshable {
            await viewModel.loadRFPs(projectId: projectId)
        }
        .task {
            await viewModel.loadRFPs(projectId: projectId)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "megaphone")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No requests yet")
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text("Post a request and let vendors come to you with bids")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showCreateRFP = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("NEW RFP")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1.5)
                )
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - RFP List
    
    private var rfpList: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Manage your requests for proposals")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.rfps) { rfp in
                        RFPExpandableCard(
                            rfp: rfp,
                            isExpanded: expandedRFPId == rfp.id,
                            onToggle: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    expandedRFPId = expandedRFPId == rfp.id ? nil : rfp.id
                                }
                            },
                            onRefresh: {
                                Task { await viewModel.loadRFPs(projectId: projectId) }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Expandable RFP Card

struct RFPExpandableCard: View {
    let rfp: RFP
    let isExpanded: Bool
    let onToggle: () -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader
            statsRow.padding(.top, 16)
            
            if isExpanded {
                bidsSection.padding(.top, 20)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var cardHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(rfp.title)
                        .font(.custom("DelaGothicOne-Regular", size: 17))
                        .lineLimit(2)
                    
                    StatusBadge(status: rfp.status)
                }
                
                Text("Posted \(rfp.createdAt.timeAgoDisplay())")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 32, height: 32)
            }
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: 10) {
            StatBox(icon: "dollarsign", label: "BUDGET", value: rfp.budgetFormatted, bgColor: Color(hex: "F5F1E8"))
            StatBox(icon: "person.2", label: "BIDS", value: "\(rfp.bidCount) received", bgColor: Color(hex: "F5F1E8"))
            StatBox(icon: "clock", label: "TIME LEFT", value: timeLeftText, bgColor: Color(hex: "FFEBE5"), valueColor: Color(hex: "FF6B35"))
        }
    }
    
    private var timeLeftText: String {
        guard let deadline = rfp.deadline else { return "No deadline" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        if days <= 0 { return "Expired" }
        if days == 1 { return "1 day left" }
        if days < 7 { return "\(days) days left" }
        return "\(days / 7) week\(days / 7 > 1 ? "s" : "") left"
    }
    
    private var bidsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider().padding(.bottom, 4)
            
            Text("Bids (\(rfp.bidCount))")
                .font(.custom("DelaGothicOne-Regular", size: 15))
            
            if let bids = rfp.bids, !bids.isEmpty {
                ForEach(bids) { bid in
                    BidRow(bid: bid, isRFPOpen: rfp.isOpen, onRefresh: onRefresh)
                }
            } else {
                HStack {
                    Image(systemName: "envelope.open")
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No bids yet")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Stat Box

private struct StatBox: View {
    let icon: String
    let label: String
    let value: String
    var bgColor: Color
    var valueColor: Color = .black
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(bgColor)
        .cornerRadius(8)
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: RFP.RFPStatus
    
    var body: some View {
        Text(status == .open ? "ACTIVE" : status.rawValue)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(12)
    }
    
    private var color: Color {
        switch status {
        case .open: return Color(hex: "22C55E")
        case .awarded: return Color(hex: "3B82F6")
        case .closed: return .gray
        }
    }
}

// MARK: - Bid Row

private struct BidRow: View {
    let bid: Bid
    let isRFPOpen: Bool
    let onRefresh: () -> Void
    
    @State private var showAcceptConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "E5E7EB"), Color(hex: "D1D5DB")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                    
                    Text(initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bid.vendor?.name ?? "Vendor")
                        .font(.system(size: 15, weight: .semibold))
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(i < 4 ? Color(hex: "F59E0B") : Color.gray.opacity(0.3))
                        }
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
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .lineLimit(2)
            
            if bid.isSubmitted && isRFPOpen {
                HStack(spacing: 12) {
                    Button {
                        showAcceptConfirm = true
                    } label: {
                        Text("Accept Bid")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        Task {
                            _ = try? await APIService.shared.rejectBid(bidId: bid.id)
                            onRefresh()
                        }
                    } label: {
                        Text("Decline")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(12)
        .confirmationDialog("Accept Bid", isPresented: $showAcceptConfirm) {
            Button("Accept \(bid.amountFormatted)") {
                Task {
                    _ = try? await APIService.shared.acceptBid(bidId: bid.id)
                    onRefresh()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Accept \(bid.vendor?.name ?? "this vendor")'s bid?")
        }
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
            .font(.system(size: 9, weight: .bold))
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
        RFPListView(projectId: 1)
    }
}
