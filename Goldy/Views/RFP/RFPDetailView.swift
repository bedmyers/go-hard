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
    @State private var showEditSheet = false

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
        .toolbar {
            if viewModel.rfp.isOpen {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(isPresented: $showEditSheet) {
            EditRFPView(rfp: viewModel.rfp) { updatedRFP in
                viewModel.updateRFP(updatedRFP)
            }
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

                // Category badge
                if let category = viewModel.rfp.rfpCategory {
                    HStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 12))
                        Text(category.rawValue)
                            .font(.custom("Spectral-Medium", size: 13))
                    }
                    .foregroundColor(Color(hex: category.color))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: category.color).opacity(0.1))
                    .cornerRadius(12)
                }

                // Status + Visibility badges
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(statusText)
                            .font(.custom("Spectral-Medium", size: 12))
                            .foregroundColor(statusColor)
                    }

                    if let visibility = viewModel.rfp.visibility {
                        HStack(spacing: 4) {
                            Image(systemName: visibility == .public ? "globe" : "lock.fill")
                                .font(.system(size: 10))
                            Text(visibility == .public ? "Public" : "Private")
                                .font(.custom("Spectral-Medium", size: 11))
                        }
                        .foregroundColor(.gray)
                    }
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

    private func timeOfDayIcon(_ timeOfDay: String) -> String {
        switch timeOfDay.lowercased() {
        case "morning": return "sunrise.fill"
        case "afternoon": return "sun.max.fill"
        case "evening": return "moon.stars.fill"
        case "full day": return "clock.fill"
        default: return "clock.fill"
        }
    }
    
    // MARK: - Details

    private var rfpDetails: some View {
        VStack(spacing: 16) {
            // Description
            if !viewModel.rfp.description.isEmpty {
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
            }

            // Event Info Row
            eventInfoSection

            // Budget & Timeline Row
            HStack(spacing: 12) {
                DetailCard(
                    icon: "dollarsign.circle.fill",
                    title: "Budget",
                    value: viewModel.rfp.budgetFormatted
                )

                if let deadline = viewModel.rfp.deadline {
                    DetailCard(
                        icon: "clock.fill",
                        title: "Bid Deadline",
                        value: deadline.formatted(date: .abbreviated, time: .omitted)
                    )
                }
            }

            // Style Tags
            if let styleTags = viewModel.rfp.styleTags, !styleTags.isEmpty {
                styleTagsSection(styleTags)
            }

            // Requirements
            requirementsSection

            // Inspiration Link
            if let inspirationUrl = viewModel.rfp.inspirationUrl, !inspirationUrl.isEmpty {
                inspirationSection(inspirationUrl)
            }
        }
    }

    private var eventInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Details")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)

            HStack(spacing: 16) {
                // Event Date
                if let eventDate = viewModel.rfp.eventDate {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "3B82F6"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Event Date")
                                .font(.custom("Spectral-Medium", size: 10))
                                .foregroundColor(.gray)
                            Text(eventDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.custom("Spectral-Bold", size: 14))
                        }
                    }
                }

                // Time of Day
                if let timeOfDay = viewModel.rfp.timeOfDay {
                    HStack(spacing: 6) {
                        Image(systemName: timeOfDayIcon(timeOfDay))
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "F59E0B"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time")
                                .font(.custom("Spectral-Medium", size: 10))
                                .foregroundColor(.gray)
                            Text(timeOfDay)
                                .font(.custom("Spectral-Bold", size: 14))
                        }
                    }
                }

                Spacer()

                // Guest Count
                if let guestCount = viewModel.rfp.guestCount {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8B5CF6"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Guests")
                                .font(.custom("Spectral-Medium", size: 10))
                                .foregroundColor(.gray)
                            Text("\(guestCount)")
                                .font(.custom("Spectral-Bold", size: 14))
                        }
                    }
                }
            }

            // Location
            if let location = viewModel.rfp.location, !location.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "22C55E"))
                    Text(location)
                        .font(.custom("Spectral-Medium", size: 14))
                }
            }

            // Decision Date
            if let decisionDate = viewModel.rfp.decisionDate {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "F59E0B"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Decision by")
                            .font(.custom("Spectral-Medium", size: 10))
                            .foregroundColor(.gray)
                        Text(decisionDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.custom("Spectral-Medium", size: 14))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private func styleTagsSection(_ tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Style")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)

            FlowLayoutSimple(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag.replacingOccurrences(of: "-", with: " ").capitalized)
                        .font(.custom("Spectral-Medium", size: 12))
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "8B5CF6").opacity(0.1))
                        .cornerRadius(14)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var requirementsSection: some View {
        let mustHaves = viewModel.rfp.mustHaves ?? []
        let niceToHaves = viewModel.rfp.niceToHaves ?? []

        return Group {
            if !mustHaves.isEmpty || !niceToHaves.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    // Must Haves
                    if !mustHaves.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "FF6B35"))
                                Text("Must Haves")
                                    .font(.custom("Spectral-Bold", size: 12))
                                    .foregroundColor(.gray)
                            }

                            ForEach(mustHaves, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: "FF6B35"))
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    Text(item)
                                        .font(.custom("Spectral-Regular", size: 14))
                                }
                            }
                        }
                    }

                    // Nice to Haves
                    if !niceToHaves.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "22C55E"))
                                Text("Nice to Haves")
                                    .font(.custom("Spectral-Bold", size: 12))
                                    .foregroundColor(.gray)
                            }

                            ForEach(niceToHaves, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: "22C55E"))
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    Text(item)
                                        .font(.custom("Spectral-Regular", size: 14))
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }

    private func inspirationSection(_ url: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inspiration")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)

            if let linkUrl = URL(string: url) {
                Link(destination: linkUrl) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.system(size: 14))
                        Text(url)
                            .font(.custom("Spectral-Regular", size: 14))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "3B82F6"))
                }
            } else {
                Text(url)
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Accepted Bid (Post-Award)

    private var acceptedBid: Bid? {
        viewModel.rfp.bids?.first { $0.status == .accepted }
    }

    private var awardedVendorSection: some View {
        Group {
            if let bid = acceptedBid, let vendor = bid.vendor {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "22C55E"))
                        Text("Vendor Hired!")
                            .font(.custom("DelaGothicOne-Regular", size: 18))
                        Spacer()
                    }

                    // Vendor card
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "FFD700").opacity(0.2))
                                    .frame(width: 60, height: 60)

                                Text(vendorInitials(vendor.name))
                                    .font(.custom("DelaGothicOne-Regular", size: 20))
                                    .foregroundColor(Color(hex: "B8860B"))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(vendor.name)
                                    .font(.custom("DelaGothicOne-Regular", size: 18))

                                if let services = vendor.services, !services.isEmpty {
                                    Text(services.prefix(2).joined(separator: " • "))
                                        .font(.custom("Spectral-Regular", size: 13))
                                        .foregroundColor(Color(hex: "8B5CF6"))
                                }

                                if let location = vendor.location {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin")
                                            .font(.system(size: 10))
                                        Text(location)
                                            .font(.custom("Spectral-Regular", size: 12))
                                    }
                                    .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(bid.amountFormatted)
                                    .font(.custom("DelaGothicOne-Regular", size: 20))
                                    .foregroundColor(Color(hex: "22C55E"))
                            }
                        }

                        Divider()

                        // Contact buttons
                        HStack(spacing: 12) {
                            if let url = URL(string: "mailto:\(vendor.email)") {
                                Link(destination: url) {
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                        Text("Email")
                                    }
                                    .font(.custom("Spectral-Bold", size: 13))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(hex: "3B82F6"))
                                    .cornerRadius(10)
                                }
                            }

                            Button {
                                showVendorProfile = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.circle")
                                    Text("View Profile")
                                }
                                .font(.custom("Spectral-Bold", size: 13))
                                .foregroundColor(Color(hex: "3B82F6"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "3B82F6").opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "22C55E").opacity(0.3), lineWidth: 2)
                    )
                }
                .sheet(isPresented: $showVendorProfile) {
                    NavigationStack {
                        VendorProfileView(vendorId: vendor.id)
                    }
                }
            }
        }
    }

    @State private var showVendorProfile = false

    private func vendorInitials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    // MARK: - Bids Section

    private var bidsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Show awarded vendor card prominently if awarded
            if viewModel.rfp.status == .awarded {
                awardedVendorSection
            }

            HStack {
                Text(viewModel.rfp.status == .awarded ? "All Bids" : "Bids")
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
                    // If awarded, show other bids collapsed/smaller
                    let displayBids = viewModel.rfp.status == .awarded
                        ? bids.filter { $0.status != .accepted }
                        : bids

                    ForEach(displayBids) { bid in
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

// MARK: - Flow Layout Simple

private struct FlowLayoutSimple: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: containerWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
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

    @State private var showVendorProfile = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Vendor avatar - tappable
                Button {
                    showVendorProfile = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "E5E7EB"))
                            .frame(width: 48, height: 48)

                        Text(initials)
                            .font(.custom("Spectral-Bold", size: 15))
                            .foregroundColor(.gray)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Vendor name - tappable
                    Button {
                        showVendorProfile = true
                    } label: {
                        Text(bid.vendor?.name ?? "Vendor")
                            .font(.custom("Spectral-Bold", size: 15))
                            .foregroundColor(.black)
                    }

                    // Services
                    if let services = bid.vendor?.services, !services.isEmpty {
                        Text(services.prefix(2).joined(separator: " • "))
                            .font(.custom("Spectral-Regular", size: 12))
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }

                    // Location
                    if let location = bid.vendor?.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(location)
                                .font(.custom("Spectral-Regular", size: 11))
                        }
                        .foregroundColor(.gray)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(bid.amountFormatted)
                        .font(.custom("DelaGothicOne-Regular", size: 18))

                    BidStatusBadge(status: bid.status)
                }
            }

            Text(bid.proposal)
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)

            // Action buttons based on status
            if bid.status == .accepted {
                // Awarded - show message
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "22C55E"))
                    Text("Bid Accepted")
                        .font(.custom("Spectral-Bold", size: 13))
                        .foregroundColor(Color(hex: "22C55E"))

                    Spacer()

                    Button {
                        showVendorProfile = true
                    } label: {
                        Text("View Profile")
                            .font(.custom("Spectral-Medium", size: 12))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                }
            } else if bid.isSubmitted && isRFPOpen {
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

                    Button {
                        showVendorProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                }
                .padding(.top, 4)
            } else {
                // Declined or closed - just show profile link
                HStack {
                    Spacer()
                    Button {
                        showVendorProfile = true
                    } label: {
                        Text("View Profile")
                            .font(.custom("Spectral-Medium", size: 12))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .sheet(isPresented: $showVendorProfile) {
            if let vendor = bid.vendor {
                NavigationStack {
                    VendorProfileView(vendorId: vendor.id)
                }
            }
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
            category: "Photography",
            timeOfDay: "Afternoon",
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
