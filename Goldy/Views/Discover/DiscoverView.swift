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
                Color("Background")
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

// Filter and Sort enums for RFPs
private enum RFPFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case awarded = "Awarded"
    case closed = "Closed"
}

private enum RFPSort: String, CaseIterable {
    case newest = "Newest First"
    case deadlineSoon = "Deadline Soon"
    case mostBids = "Most Bids"
}

private struct AllRFPsView: View {
    @State private var rfps: [RFP] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCreateRFP = false
    @State private var expandedRFPId: Int?
    @State private var selectedFilter: RFPFilter = .all
    @State private var selectedSort: RFPSort = .newest

    private var filteredAndSortedRFPs: [RFP] {
        var result = rfps

        // Filter by status
        switch selectedFilter {
        case .all:
            break
        case .active:
            result = result.filter { $0.status == .open }
        case .awarded:
            result = result.filter { $0.status == .awarded }
        case .closed:
            result = result.filter { $0.status == .closed }
        }

        // Sort
        switch selectedSort {
        case .newest:
            result = result.sorted { $0.createdAt > $1.createdAt }
        case .deadlineSoon:
            result = result.sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
        case .mostBids:
            result = result.sorted { $0.bidCount > $1.bidCount }
        }

        return result
    }
    
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
                .font(.custom("Spectral-Regular", size: 14))
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
                // Filter chips + Sort button row
                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(RFPFilter.allCases, id: \.self) { filter in
                                RFPFilterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                    }

                    Menu {
                        ForEach(RFPSort.allCases, id: \.self) { sort in
                            Button {
                                selectedSort = sort
                            } label: {
                                HStack {
                                    Text(sort.rawValue)
                                    if selectedSort == sort {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14))
                            .foregroundColor(selectedSort != .newest ? Color(hex: "3B82F6") : .gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                Text("\(filteredAndSortedRFPs.count) request\(filteredAndSortedRFPs.count == 1 ? "" : "s")")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                LazyVStack(spacing: 16) {
                    ForEach(filteredAndSortedRFPs) { rfp in
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
    }
    
    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Project badge + Category badge row
            HStack(spacing: 8) {
                if let project = rfp.project {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                        Text(project.title)
                            .font(.custom("Spectral-Medium", size: 11))
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
                            .font(.custom("Spectral-Medium", size: 11))
                    }
                    .foregroundColor(Color(hex: "8B5CF6"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "8B5CF6").opacity(0.1))
                    .cornerRadius(6)
                }

                // Category badge
                if let category = rfp.rfpCategory {
                    HStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 10))
                        Text(category.rawValue)
                            .font(.custom("Spectral-Medium", size: 11))
                    }
                    .foregroundColor(Color(hex: category.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: category.color).opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
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

                        StatusBadge(status: rfp.status)
                    }

                    HStack(spacing: 12) {
                        Text("Posted \(rfp.createdAt.timeAgoDisplay())")
                            .font(.custom("Spectral-Regular", size: 13))
                            .foregroundColor(.gray)

                        if let eventDate = rfp.eventDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text(eventDate, style: .date)
                                    .font(.custom("Spectral-Regular", size: 12))
                            }
                            .foregroundColor(Color(hex: "8B5CF6"))
                        }

                        if let location = rfp.location, !location.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 10))
                                Text(location)
                                    .font(.custom("Spectral-Regular", size: 12))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.gray)
                        }

                        if let guestCount = rfp.guestCount {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2")
                                    .font(.system(size: 10))
                                Text("\(guestCount)")
                                    .font(.custom("Spectral-Regular", size: 12))
                            }
                            .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()

                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.custom("Spectral-Medium", size: 14))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                }
            }
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: 10) {
            StatBox(icon: "dollarsign", label: "BUDGET", value: rfp.budgetFormatted, bgColor: Color("Background"))
            StatBox(icon: "person.2", label: "BIDS", value: "\(rfp.bidCount) received", bgColor: Color("Background"))
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
                        .font(.custom("Spectral-Regular", size: 14))
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

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: RFP.RFPStatus
    
    var body: some View {
        Text(status == .open ? "ACTIVE" : status.rawValue)
            .font(.custom("Spectral-Bold", size: 10))
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
                        .font(.custom("Spectral-Bold", size: 14))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bid.vendor?.name ?? "Vendor")
                        .font(.custom("Spectral-Bold", size: 15))

                    // Vendor services
                    if let services = bid.vendor?.services, !services.isEmpty {
                        Text(services.prefix(2).joined(separator: " • "))
                            .font(.custom("Spectral-Regular", size: 12))
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }

                    // Vendor location
                    if let location = bid.vendor?.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(location)
                                .font(.custom("Spectral-Regular", size: 12))
                        }
                        .foregroundColor(.gray)
                    }

                    Text(bid.proposal)
                        .font(.custom("Spectral-Regular", size: 13))
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
                            .font(.custom("Spectral-Bold", size: 13))
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
                            .font(.custom("Spectral-Medium", size: 13))
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
    @StateObject private var viewModel = VendorMarketplaceViewModel()
    @State private var showFilters = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar + filter button
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search vendors...", text: $viewModel.searchQuery)
                        .onChange(of: viewModel.searchQuery) { _, _ in
                            viewModel.debouncedSearch()
                        }
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                            Task { await viewModel.search() }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                
                Button {
                    showFilters.toggle()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.custom("Spectral-Regular", size: 16))
                            .foregroundColor(viewModel.hasActiveFilters ? .white : .gray)
                            .frame(width: 44, height: 44)
                            .background(viewModel.hasActiveFilters ? Color(hex: "3B82F6") : Color.white)
                            .cornerRadius(12)
                        
                        if viewModel.hasActiveFilters {
                            Circle()
                                .fill(Color(hex: "FF6B35"))
                                .frame(width: 10, height: 10)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Active filters display
            if viewModel.portfolioOnly {
                activeFiltersRow
            }

            // Combined filter chips row (cities + categories)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // City chips
                    LocationChip(title: "All", isSelected: viewModel.selectedLocation == nil) {
                        viewModel.selectedLocation = nil
                        Task { await viewModel.search() }
                    }

                    ForEach(viewModel.locations, id: \.self) { location in
                        // Show just city name without state
                        let cityName = location.components(separatedBy: ",").first ?? location
                        LocationChip(title: cityName, isSelected: viewModel.selectedLocation == location) {
                            viewModel.selectedLocation = location
                            Task { await viewModel.search() }
                        }
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 20)
                        .padding(.horizontal, 4)

                    // Category chips
                    ForEach(VendorCategory.allCases) { category in
                        CategoryChip(title: category.displayName, isSelected: viewModel.selectedCategory == category) {
                            if viewModel.selectedCategory == category {
                                viewModel.selectedCategory = nil
                            } else {
                                viewModel.selectedCategory = category
                            }
                            Task { await viewModel.search() }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 12)
            
            // Results
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.filteredVendors.isEmpty {
                emptyState
            } else {
                vendorList
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.search()
        }
    }
    
    private var activeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if viewModel.portfolioOnly {
                    FilterTag(label: "Has Portfolio") {
                        viewModel.portfolioOnly = false
                        Task { await viewModel.search() }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.custom("Spectral-Regular", size: 48))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Vendors Found")
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text("Try adjusting your filters")
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
            
            if viewModel.hasActiveFilters {
                Button {
                    viewModel.clearFilters()
                    Task { await viewModel.search() }
                } label: {
                    Text("Clear All Filters")
                        .font(.custom("Spectral-Bold", size: 14))
                        .foregroundColor(Color(hex: "3B82F6"))
                }
            }
            Spacer()
        }
    }
    
    private var vendorList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Text("\(viewModel.filteredVendors.count) vendor\(viewModel.filteredVendors.count == 1 ? "" : "s")")
                    .font(.custom("Spectral-Regular", size: 13))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ForEach(viewModel.filteredVendors) { vendor in
                    NavigationLink(destination: VendorProfileView(vendorId: vendor.id)) {
                        VendorRowCard(vendor: vendor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .refreshable {
            await viewModel.search()
        }
    }
}

// MARK: - Filter Tag

private struct FilterTag: View {
    let label: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.custom("Spectral-Medium", size: 12))
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.custom("Spectral-Bold", size: 10))
            }
        }
        .foregroundColor(Color(hex: "3B82F6"))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "3B82F6").opacity(0.1))
        .cornerRadius(14)
    }
}

// MARK: - Filter Sheet

private struct FilterSheet: View {
    @ObservedObject var viewModel: VendorMarketplaceViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Location
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LOCATION")
                                .font(.custom("Spectral-Bold", size: 12))
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 8) {
                                LocationOption(title: "All Locations", isSelected: viewModel.selectedLocation == nil) {
                                    viewModel.selectedLocation = nil
                                }
                                
                                ForEach(viewModel.locations, id: \.self) { location in
                                    LocationOption(title: location, isSelected: viewModel.selectedLocation == location) {
                                        viewModel.selectedLocation = location
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Portfolio filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("QUALITY FILTERS")
                                .font(.custom("Spectral-Bold", size: 12))
                                .foregroundColor(.gray)
                            
                            Toggle(isOn: $viewModel.portfolioOnly) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.custom("Spectral-Regular", size: 18))
                                        .foregroundColor(Color(hex: "8B5CF6"))
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Has Portfolio")
                                            .font(.custom("Spectral-Medium", size: 15))
                                        Text("Only show vendors with photos")
                                            .font(.custom("Spectral-Regular", size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .tint(Color(hex: "22C55E"))
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.search()
                            dismiss()
                        }
                    } label: {
                        Text("Apply")
                            .font(.custom("Spectral-Bold", size: 15))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "FFD700"))
                            .cornerRadius(16)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Location Option

private struct LocationOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(isSelected ? Color(hex: "3B82F6") : .gray.opacity(0.5))
                
                Text(title)
                    .font(.custom("Spectral-Regular", size: 15))
                    .foregroundColor(.black)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.custom("Spectral-Bold", size: 14))
                        .foregroundColor(Color(hex: "22C55E"))
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
    }
}

// MARK: - RFP Filter Chip

private struct RFPFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Spectral-Medium", size: 13))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black : Color.white)
                .cornerRadius(16)
        }
    }
}

// MARK: - Location Chip

private struct LocationChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if title != "All" {
                    Image(systemName: "mappin")
                        .font(.system(size: 9))
                }
                Text(title)
                    .font(.custom("Spectral-Medium", size: 13))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "3B82F6") : Color.white)
            .cornerRadius(16)
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Spectral-Medium", size: 13))
                .foregroundColor(isSelected ? .black : .gray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "FFD700") : Color.white)
                .cornerRadius(16)
        }
    }
}

// MARK: - Vendor Row Card

private struct VendorRowCard: View {
    let vendor: User

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FFD700").opacity(0.2))
                    .frame(width: 56, height: 56)

                Text(vendor.initials)
                    .font(.custom("DelaGothicOne-Regular", size: 18))
                    .foregroundColor(Color(hex: "B8860B"))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(vendor.name)
                        .font(.custom("Spectral-Bold", size: 16))
                        .foregroundColor(.black)

                    // Verified badge
                    if vendor.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                }

                if let services = vendor.services, !services.isEmpty {
                    Text(services.prefix(2).joined(separator: " • "))
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(Color(hex: "8B5CF6"))
                }

                // Location + years experience + portfolio
                HStack(spacing: 0) {
                    if let location = vendor.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(location)
                                .font(.custom("Spectral-Regular", size: 12))
                        }
                        .foregroundColor(.gray)
                    }

                    if let expText = vendor.experienceText {
                        if vendor.location != nil {
                            Text(" · ")
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.gray)
                        }
                        Text(expText)
                            .font(.custom("Spectral-Regular", size: 12))
                            .foregroundColor(.gray)
                    }

                    if let urls = vendor.portfolioUrls, !urls.isEmpty {
                        if vendor.location != nil || vendor.experienceText != nil {
                            Text(" · ")
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.gray)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.system(size: 10))
                            Text("\(urls.count) photos")
                                .font(.custom("Spectral-Regular", size: 12))
                        }
                        .foregroundColor(Color(hex: "22C55E"))
                    }
                }
            }

            Spacer()

            // Starting price on the right
            if let price = vendor.startingPriceFormatted {
                Text(price)
                    .font(.custom("Spectral-Bold", size: 16))
                    .foregroundColor(Color(hex: "22C55E"))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(10)
    }
}

#Preview {
    DiscoverView()
}
