//
//  VendorDiscoverView.swift
//  Goldy
//
//  Created by Blair Myers on 11/30/25.
//

import SwiftUI

struct VendorDiscoverView: View {
    @State private var selectedTab: VendorTab = .browse
    
    enum VendorTab: String, CaseIterable {
        case browse = "Find Work"
        case myBids = "My Bids"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(VendorTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if selectedTab == .browse {
                        VendorBrowseContent()
                    } else {
                        VendorBidsContent()
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Browse Content

private struct VendorBrowseContent: View {
    @State private var rfps: [RFP] = []
    @State private var isLoading = true
    @State private var selectedRFP: RFP?
    
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
        .task {
            await loadRFPs()
        }
        .refreshable {
            await loadRFPs()
        }
        .sheet(item: $selectedRFP) { rfp in
            RFPBidSheet(rfp: rfp) {
                Task { await loadRFPs() }
                selectedRFP = nil
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Open Requests")
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text("Check back soon - couples post new requests all the time")
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var rfpList: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("\(rfps.count) open request\(rfps.count == 1 ? "" : "s")")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 16) {
                    ForEach(rfps) { rfp in
                        OpenRFPCard(rfp: rfp) {
                            selectedRFP = rfp
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private func loadRFPs() async {
        do {
            rfps = try await APIService.shared.browseOpenRFPs()
        } catch {
            print("❌ Error: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Open RFP Card

private struct OpenRFPCard: View {
    let rfp: RFP
    let onBid: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(rfp.title)
                        .font(.custom("DelaGothicOne-Regular", size: 17))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 12) {
                        if let location = rfp.location, !location.isEmpty {
                            Label(location, systemImage: "mappin")
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        Label("Posted \(rfp.createdAt.timeAgoDisplay())", systemImage: "clock")
                            .font(.custom("Spectral-Regular", size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(rfp.budgetFormatted)
                        .font(.custom("DelaGothicOne-Regular", size: 18))
                        .foregroundColor(Color(hex: "22C55E"))
                    Text("budget")
                        .font(.custom("Spectral-Regular", size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            // Description
            Text(rfp.description)
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .lineLimit(3)
            
            // Event details row
            HStack(spacing: 16) {
                if let eventDate = rfp.eventDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                        Text(eventDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(Color(hex: "3B82F6"))
                }
                
                if let guestCount = rfp.guestCount {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                        Text("\(guestCount) guests")
                    }
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Style tags
            if let tags = rfp.styleTags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.custom("Spectral-Medium", size: 11))
                                .foregroundColor(Color(hex: "8B5CF6"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "8B5CF6").opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Must haves
            if let mustHaves = rfp.mustHaves, !mustHaves.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Must haves:")
                        .font(.custom("Spectral-Bold", size: 11))
                        .foregroundColor(Color(hex: "FF6B35"))
                    
                    ForEach(mustHaves.prefix(2), id: \.self) { item in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.custom("Spectral-Regular", size: 10))
                                .foregroundColor(Color(hex: "FF6B35"))
                            Text(item)
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            // Pinterest link - NOW TAPPABLE
            if let urlString = rfp.inspirationUrl, !urlString.isEmpty, let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.custom("Spectral-Regular", size: 10))
                        Text("View mood board")
                            .font(.custom("Spectral-Medium", size: 11))
                        Image(systemName: "arrow.up.right")
                            .font(.custom("Spectral-Regular", size: 9))
                    }
                    .foregroundColor(Color(hex: "E60023"))
                }
            }
            
            // Footer stats
            HStack(spacing: 16) {
                if let deadline = rfp.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "hourglass")
                        Text("Due \(deadline.formatted(date: .abbreviated, time: .omitted))")
                    }
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(Color(hex: "FF6B35"))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                    Text("\(rfp.bidCount) bid\(rfp.bidCount == 1 ? "" : "s")")
                }
                .font(.custom("Spectral-Regular", size: 12))
                .foregroundColor(.gray)
                
                Spacer()
            }
            
            // Bid button
            Button(action: onBid) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("SUBMIT BID")
                        .font(.custom("DelaGothicOne-Regular", size: 13))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "FFD700"))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
            }
}

// MARK: - Bids Content

private struct VendorBidsContent: View {
    @State private var bids: [Bid] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if bids.isEmpty {
                emptyState
            } else {
                bidsList
            }
        }
        .task {
            await loadBids()
        }
        .refreshable {
            await loadBids()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "paperplane")
                .font(.custom("Spectral-Regular", size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Bids Yet")
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text("Browse open requests and submit your first bid")
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var bidsList: some View {
        ScrollView {
            VStack(spacing: 16) {
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
    
    private var bidStats: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(bids.count)", label: "Total", color: Color(hex: "3B82F6"))
            StatCard(value: "\(bids.filter { $0.status == .submitted }.count)", label: "Pending", color: Color(hex: "F59E0B"))
            StatCard(value: "\(bids.filter { $0.status == .accepted }.count)", label: "Won", color: Color(hex: "22C55E"))
        }
    }
    
    private func loadBids() async {
        do {
            bids = try await APIService.shared.getMyBids()
        } catch {
            print("❌ Error: \(error)")
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bid.rfp?.title ?? "Request #\(bid.rfpId)")
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                    
                    Text("Submitted \(bid.createdAt.timeAgoDisplay())")
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                BidStatusBadge(status: bid.status)
            }
            
            HStack {
                Text("Your bid:")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                Text(bid.amountFormatted)
                    .font(.custom("DelaGothicOne-Regular", size: 18))
                    .foregroundColor(Color(hex: "22C55E"))
            }
            
            Text(bid.proposal)
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .lineLimit(2)
            
            statusMessage
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
                .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(bid.status == .accepted ? Color(hex: "22C55E") : .clear, lineWidth: 2)
        )
    }
    
    @ViewBuilder
    private var statusMessage: some View {
        switch bid.status {
        case .submitted:
            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text("Waiting for response")
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
                Text("You got the job!")
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
                Text("Not selected")
            }
            .font(.custom("Spectral-Regular", size: 12))
            .foregroundColor(.gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
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
        case .accepted: return "WON"
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
    VendorDiscoverView()
}
