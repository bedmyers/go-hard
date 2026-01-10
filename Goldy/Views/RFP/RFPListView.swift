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
    @State private var rfpToEdit: RFP?
    @State private var rfpToDelete: RFP?
    @State private var showDeleteConfirm = false
    @State private var acceptedVendorName: String?
    @State private var showAcceptedConfirmation = false

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
                            .font(.custom("Spectral-Bold", size: 12))
                        Text("New RFP")
                            .font(.custom("Spectral-Bold", size: 13))
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
        .sheet(item: $rfpToEdit) { rfp in
            EditRFPView(rfp: rfp) { updatedRFP in
                Task { await viewModel.loadRFPs(projectId: projectId) }
            }
        }
        .alert("Bid Accepted!", isPresented: $showAcceptedConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(acceptedVendorName ?? "The vendor") has been added to your project. You can view and manage them in the project's vendor list.")
        }
        .alert("Delete RFP", isPresented: $showDeleteConfirm, presenting: rfpToDelete) { rfp in
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.closeRFP(rfp)
                    await viewModel.loadRFPs(projectId: projectId)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { rfp in
            Text("Are you sure you want to close \"\(rfp.title)\"? This cannot be undone.")
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
                .font(.custom("Spectral-Regular", size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No requests yet")
                .font(.custom("DelaGothicOne-Regular", size: 20))

            Text("Post a request and let vendors come to you with bids")
                .font(.custom("Spectral-Regular", size: 14))
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
                Text("All your requests for proposals")
                    .font(.custom("Spectral-Regular", size: 14))
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
                            onEdit: {
                                rfpToEdit = rfp
                            },
                            onDelete: {
                                rfpToDelete = rfp
                                showDeleteConfirm = true
                            },
                            onBidAccepted: { vendorName in
                                acceptedVendorName = vendorName
                                showAcceptedConfirmation = true
                                Task { await viewModel.loadRFPs(projectId: self.projectId) }
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
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onBidAccepted: (String?) -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader
            projectTag.padding(.top, 8)
            locationDateRow.padding(.top, 8)
            statsRow.padding(.top, 12)

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
                    NavigationLink(destination: RFPDetailView(rfp: rfp)) {
                        Text(rfp.title)
                            .font(.custom("DelaGothicOne-Regular", size: 17))
                            .foregroundColor(.black)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    RFPStatusBadge(rfp: rfp)
                }

                Text("Posted \(rfp.createdAt.timeAgoDisplay())")
                    .font(.custom("Spectral-Regular", size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Menu button
            Menu {
                NavigationLink(destination: RFPDetailView(rfp: rfp)) {
                    Label("View Details", systemImage: "eye")
                }

                if rfp.isOpen {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Close RFP", systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.custom("Spectral-Medium", size: 16))
                    .foregroundColor(.gray)
                    .frame(width: 32, height: 32)
            }
        }
    }

    private var projectTag: some View {
        Group {
            if let project = rfp.project {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                    Text(project.title)
                        .font(.custom("Spectral-Medium", size: 11))
                }
                .foregroundColor(Color(hex: "8B5CF6"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "8B5CF6").opacity(0.1))
                .cornerRadius(6)
            } else {
                Text("Standalone")
                    .font(.custom("Spectral-Medium", size: 11))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }

    private var locationDateRow: some View {
        HStack(spacing: 16) {
            if let location = rfp.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text(location)
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)
                }
            }

            if let eventDate = rfp.eventDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text(eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatBox(icon: "dollarsign", label: "BUDGET", value: rfp.budgetFormatted, bgColor: Color("Background"))
            StatBox(icon: "person.2", label: "BIDS", value: "\(rfp.bidCount) bids", bgColor: Color("Background"))

            // Only show Time Left for open RFPs
            if rfp.status == .open {
                StatBox(icon: "clock", label: "TIME LEFT", value: timeLeftText, bgColor: timeLeftBgColor, valueColor: timeLeftColor)
            }
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

    private var timeLeftColor: Color {
        guard let deadline = rfp.deadline else { return .gray }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        if days <= 0 { return .red }
        if days <= 3 { return Color(hex: "FF6B35") }
        return Color(hex: "FF6B35")
    }

    private var timeLeftBgColor: Color {
        guard let deadline = rfp.deadline else { return Color("Background") }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        if days <= 0 { return Color.red.opacity(0.1) }
        return Color(hex: "FFEBE5")
    }

    private var bidsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider().padding(.bottom, 4)

            HStack {
                Text("Bids (\(rfp.bidCount))")
                    .font(.custom("DelaGothicOne-Regular", size: 15))

                Spacer()

                Button(action: onToggle) {
                    Image(systemName: "chevron.up")
                        .font(.custom("Spectral-Medium", size: 14))
                        .foregroundColor(.gray)
                }
            }

            if let bids = rfp.bids, !bids.isEmpty {
                ForEach(bids) { bid in
                    BidRowExpanded(
                        bid: bid,
                        isRFPOpen: rfp.isOpen,
                        onBidAccepted: onBidAccepted,
                        onRefresh: onRefresh
                    )
                }
            } else {
                HStack {
                    Image(systemName: "envelope.open")
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No bids yet")
                        .font(.custom("Spectral-Regular", size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            // View all details button
            NavigationLink(destination: RFPDetailView(rfp: rfp)) {
                HStack {
                    Text("View Full Details")
                        .font(.custom("Spectral-Medium", size: 13))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color(hex: "3B82F6"))
            }
            .padding(.top, 8)
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
                    .font(.custom("Spectral-Regular", size: 10))
                    .foregroundColor(.gray)
                Text(label)
                    .font(.custom("Spectral-Bold", size: 9))
                    .foregroundColor(.gray)
            }

            Text(value)
                .font(.custom("Spectral-Bold", size: 12))
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

// MARK: - RFP Status Badge (with expiry check)

private struct RFPStatusBadge: View {
    let rfp: RFP

    private var isExpired: Bool {
        guard let deadline = rfp.deadline else { return false }
        return deadline < Date()
    }

    private var displayStatus: String {
        if rfp.status == .open && isExpired {
            return "EXPIRED"
        }
        switch rfp.status {
        case .open: return "ACTIVE"
        case .awarded: return "AWARDED"
        case .closed: return "CLOSED"
        }
    }

    private var color: Color {
        if rfp.status == .open && isExpired {
            return .red
        }
        switch rfp.status {
        case .open: return Color(hex: "22C55E")
        case .awarded: return Color(hex: "3B82F6")
        case .closed: return .gray
        }
    }

    var body: some View {
        Text(displayStatus)
            .font(.custom("Spectral-Bold", size: 10))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(12)
    }
}

// MARK: - Expanded Bid Row

private struct BidRowExpanded: View {
    let bid: Bid
    let isRFPOpen: Bool
    let onBidAccepted: (String?) -> Void
    let onRefresh: () -> Void

    @State private var showAcceptConfirm = false
    @State private var showVendorProfile = false
    @State private var isAccepting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Vendor avatar - tappable
                Button {
                    showVendorProfile = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "E5E7EB"), Color(hex: "D1D5DB")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)

                        Text(initials)
                            .font(.custom("Spectral-Bold", size: 16))
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

                    // Rating
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: "star.fill")
                                .font(.custom("Spectral-Regular", size: 10))
                                .foregroundColor(i < 4 ? Color(hex: "F59E0B") : Color.gray.opacity(0.3))
                        }
                        Text("4.0")
                            .font(.custom("Spectral-Medium", size: 10))
                            .foregroundColor(.gray)
                    }

                    // Services summary
                    if let services = bid.vendor?.services, !services.isEmpty {
                        Text(services.prefix(2).joined(separator: " • "))
                            .font(.custom("Spectral-Regular", size: 11))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(bid.amountFormatted)
                        .font(.custom("DelaGothicOne-Regular", size: 18))

                    BidStatusBadgePrivate(status: bid.status)
                }
            }

            // Proposal text
            Text(bid.proposal)
                .font(.custom("Spectral-Regular", size: 13))
                .foregroundColor(.gray)
                .lineLimit(3)

            // Show different UI based on bid status
            if bid.status == .accepted {
                // Awarded bid - show awarded message
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "22C55E"))
                    Text("Awarded to \(bid.vendor?.name ?? "this vendor")")
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
                // Pending bid on open RFP - show action buttons
                HStack(spacing: 12) {
                    Button {
                        showAcceptConfirm = true
                    } label: {
                        HStack {
                            if isAccepting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Accept Bid")
                                    .font(.custom("Spectral-Bold", size: 13))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .cornerRadius(8)
                    }
                    .disabled(isAccepting)

                    Button {
                        Task {
                            _ = try? await APIService.shared.rejectBid(bidId: bid.id)
                            onRefresh()
                        }
                    } label: {
                        Text("Decline")
                            .font(.custom("Spectral-Medium", size: 13))
                            .foregroundColor(.gray)
                    }

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
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(12)
        .confirmationDialog("Accept Bid", isPresented: $showAcceptConfirm) {
            Button("Accept \(bid.amountFormatted)") {
                Task {
                    isAccepting = true
                    do {
                        _ = try await APIService.shared.acceptBid(bidId: bid.id)
                        onBidAccepted(bid.vendor?.name)
                    } catch {
                        print("❌ Error accepting bid: \(error)")
                        onRefresh()
                    }
                    isAccepting = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Accept \(bid.vendor?.name ?? "this vendor")'s bid? They will be added to your project.")
        }
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

private struct BidStatusBadgePrivate: View {
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
        RFPListView(projectId: 1)
    }
}
