//
//  DiscoverView.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI

struct DiscoverView: View {
    @State private var selectedMode: DiscoverMode = .rfps
    
    enum DiscoverMode: String, CaseIterable {
        case rfps = "My RFPs"
        case browse = "Find Vendors"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(DiscoverMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if selectedMode == .rfps {
                        AllRFPsView()
                    } else {
                        BrowseVendorsView()
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - All RFPs View

private struct AllRFPsView: View {
    @State private var rfps: [RFP] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCreateRFP = false
    @State private var expandedRFPId: Int?
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if rfps.isEmpty {
                emptyState
            } else {
                rfpList
            }
        }
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
            CreateRFPView { _ in
                Task { await loadRFPs() }
            }
        }
        .task {
            await loadRFPs()
        }
        .refreshable {
            await loadRFPs()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "megaphone")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No RFPs Yet")
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
                    Text("POST YOUR FIRST RFP")
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
        .frame(maxHeight: .infinity)
    }
    
    private var rfpList: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("All your requests for proposals")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 16) {
                    ForEach(rfps) { rfp in
                        RFPCardWithProject(
                            rfp: rfp,
                            isExpanded: expandedRFPId == rfp.id,
                            onToggle: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    expandedRFPId = expandedRFPId == rfp.id ? nil : rfp.id
                                }
                            },
                            onRefresh: {
                                Task { await loadRFPs() }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private func loadRFPs() async {
        do {
            rfps = try await APIService.shared.getMyRFPs()
            print("✅ Loaded \(rfps.count) RFPs")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading RFPs: \(error)")
        }
        isLoading = false
    }
}

// MARK: - RFP Card With Project Badge

private struct RFPCardWithProject: View {
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
        VStack(alignment: .leading, spacing: 8) {
            // Project badge
            if let project = rfp.project {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                    Text(project.title)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(hex: "3B82F6"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "3B82F6").opacity(0.1))
                .cornerRadius(6)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text("Standalone")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(hex: "8B5CF6"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "8B5CF6").opacity(0.1))
                .cornerRadius(6)
            }
            
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
                    BidRowCompact(bid: bid, isRFPOpen: rfp.isOpen, onRefresh: onRefresh)
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

// MARK: - Bid Row Compact

private struct BidRowCompact: View {
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
                        .frame(width: 44, height: 44)
                    
                    Text(initials)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bid.vendor?.name ?? "Vendor")
                        .font(.system(size: 15, weight: .semibold))
                    
                    Text(bid.proposal)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(bid.amountFormatted)
                    .font(.custom("DelaGothicOne-Regular", size: 16))
            }
            
            if bid.isSubmitted && isRFPOpen {
                HStack(spacing: 12) {
                    Button {
                        showAcceptConfirm = true
                    } label: {
                        Text("Accept")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
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

// MARK: - Browse Vendors

private struct BrowseVendorsView: View {
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search vendors...", text: $searchText)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("Find Vendors")
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text("Browse photographers, caterers, venues and more")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    DiscoverView()
}
