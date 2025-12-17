//
//  ProjectDetailView.swift
//  Goldy
//
//  Created by Blair Myers on 11/25/25.
//

import SwiftUI

struct ProjectDetailView: View {
    @StateObject private var viewModel: ProjectDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: ProjectTab = .overview
    
    init(project: Project) {
        _viewModel = StateObject(wrappedValue: ProjectDetailViewModel(project: project))
    }
    
    enum ProjectTab: String, CaseIterable {
        case overview = "Overview"
        case vendors = "Vendors"
        case budget = "Budget"
        case documents = "Documents"
        case timeline = "Timeline"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                tabBar
                tabContent
            }
        }
        .background(Color("Background"))
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            ZStack {
                if let imageURL = viewModel.project.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        defaultHeaderGradient
                    }
                } else {
                    defaultHeaderGradient
                }
            }
            .frame(height: 260)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [.black.opacity(0.6), .black.opacity(0.3), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                        Text("Back to Boards")
                            .font(.custom("Spectral-Medium", size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.4))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Text(viewModel.project.title)
                    .font(.custom("DelaGothicOne-Regular", size: 28))
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    if let eventDate = viewModel.project.eventDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                            Text(eventDate, style: .date)
                        }
                        .font(.custom("Spectral-Medium", size: 14))
                        .foregroundColor(.white.opacity(0.9))
                    }
                    
                    if let budget = viewModel.project.totalBudgetDollars {
                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign")
                            Text(formatCurrency(budget) + " Budget")
                        }
                        .font(.custom("Spectral-Medium", size: 14))
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(20)
            .padding(.top, 50)
        }
    }
    
    private var defaultHeaderGradient: some View {
        LinearGradient(
            colors: [Color(hex: "2D2D2D"), Color(hex: "4A4A4A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(ProjectTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(tab.rawValue)
                                .font(.custom(selectedTab == tab ? "Spectral-Bold" : "Spectral-Medium", size: 14))
                                .foregroundColor(selectedTab == tab ? .black : .gray)
                            
                            Rectangle()
                                .fill(selectedTab == tab ? Color.black : Color.clear)
                                .frame(height: 2)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.top, 8)
        .background(Color("Background"))
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            OverviewTab(project: viewModel.project)
        case .vendors:
            VendorsTab(project: viewModel.project, onVendorAdded: {
                Task { await viewModel.refresh() }
            })
        case .budget:
            PlaceholderTab(title: "Budget", icon: "chart.pie.fill")
        case .documents:
            PlaceholderTab(title: "Documents", icon: "doc.fill")
        case .timeline:
            PlaceholderTab(title: "Timeline", icon: "calendar.badge.clock")
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Overview Tab

private struct OverviewTab: View {
    let project: Project
    
    var body: some View {
        VStack(spacing: 16) {
            rfpQuickActionCard
                .padding(.horizontal)
                .padding(.top, 20)
            
            budgetBreakdownCard
                .padding(.horizontal)
            
            upcomingMilestonesCard
                .padding(.horizontal)
            
            if !project.vendors.isEmpty {
                quickStatsCard
                    .padding(.horizontal)
            }
            
            Spacer(minLength: 40)
        }
    }
    
    // MARK: - RFP Quick Action Card
    
    private var rfpQuickActionCard: some View {
        NavigationLink(destination: RFPListView(projectId: project.id)) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "FFD700").opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "megaphone.fill")
                        .font(.custom("Spectral-Regular", size: 24))
                        .foregroundColor(Color(hex: "FFD700"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Request for Proposals")
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                        .foregroundColor(.black)
                    
                    Text("Post RFPs and get vendor bids")
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.custom("Spectral-Medium", size: 14))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    private var budgetBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Breakdown")
                .font(.custom("DelaGothicOne-Regular", size: 18))
            
            if project.vendors.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.custom("Spectral-Regular", size: 40))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("Add vendors to see breakdown")
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                HStack(spacing: 24) {
                    BudgetDonutChart(vendors: project.vendors)
                        .frame(width: 120, height: 120)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(project.vendors.prefix(6)) { vendor in
                            LegendItem(
                                color: colorForRole(vendor.role),
                                label: vendor.role,
                                amount: Double(vendor.amountCents) / 100.0
                            )
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private var upcomingMilestonesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                Text("Upcoming Milestones")
                    .font(.custom("DelaGothicOne-Regular", size: 18))
            }
            
            let upcomingMilestones = getUpcomingMilestones()
            
            if upcomingMilestones.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.custom("Spectral-Regular", size: 24))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No upcoming milestones")
                        .font(.custom("Spectral-Regular", size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(upcomingMilestones.prefix(4), id: \.milestone.id) { item in
                        MilestoneRow(
                            title: item.milestone.description ?? "Payment",
                            vendorName: item.vendorName,
                            dueDate: item.milestone.dueDate,
                            amount: Double(item.milestone.amountCents) / 100.0
                        )
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "FEF9E7"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private var quickStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.custom("DelaGothicOne-Regular", size: 18))
            
            HStack(spacing: 0) {
                StatItem(
                    label: "Total Spent",
                    value: formatCurrency(totalSpent)
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    label: "In Escrow",
                    value: formatCurrency(project.totalAmountInEscrow)
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    label: "Remaining",
                    value: formatCurrency(remainingBudget)
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private var totalSpent: Double {
        let releasedAmount = project.vendors
            .compactMap { $0.escrow?.milestones }
            .flatMap { $0 }
            .filter { $0.released }
            .reduce(0) { $0 + $1.amountCents }
        return Double(releasedAmount) / 100.0
    }
    
    private var remainingBudget: Double {
        guard let budget = project.totalBudgetDollars else { return 0 }
        return budget - totalSpent - project.totalAmountInEscrow
    }
    
    private func getUpcomingMilestones() -> [(milestone: Milestone, vendorName: String)] {
        project.vendors
            .flatMap { vendor in
                (vendor.escrow?.milestones ?? [])
                    .filter { !$0.released }
                    .map { (milestone: $0, vendorName: vendor.vendor.name) }
            }
            .sorted { ($0.milestone.dueDate ?? .distantFuture) < ($1.milestone.dueDate ?? .distantFuture) }
    }
    
    private func colorForRole(_ role: String) -> Color {
        let roles = ["Venue", "Catering", "Photography", "Florals", "Music/DJ", "Other"]
        let colors: [Color] = [
            Color(hex: "E9D5FF"),
            Color(hex: "BBF7D0"),
            Color(hex: "FF6B35"),
            Color(hex: "90EE90"),
            Color(hex: "FFD700"),
            Color(hex: "87CEEB")
        ]
        
        if let index = roles.firstIndex(where: { role.lowercased().contains($0.lowercased()) }) {
            return colors[index]
        }
        return colors[roles.count - 1]
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Vendors Tab

private struct VendorsTab: View {
    let project: Project
    let onVendorAdded: () -> Void
    @State private var showAddVendor = false
    
    private var columns: [GridItem] {
        if project.vendors.count <= 1 {
            return [GridItem(.flexible())]
        } else {
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Vendors (\(project.vendors.count))")
                    .font(.custom("DelaGothicOne-Regular", size: 20))
                
                Spacer()
                
                Button {
                    showAddVendor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.custom("Spectral-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            if project.vendors.isEmpty {
                emptyVendorsState
            } else {
                quickStatsFloating
                    .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(project.vendors) { vendor in
                        NavigationLink(destination: VendorDetailView(projectVendor: vendor)) {
                            VendorCard(vendor: vendor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer(minLength: 40)
        }
        .sheet(isPresented: $showAddVendor, onDismiss: {
            onVendorAdded()
        }) {
            AddVendorView(project: project)
        }
    }
    
    private var emptyVendorsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.custom("Spectral-Regular", size: 48))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Vendors Yet")
                .font(.custom("DelaGothicOne-Regular", size: 18))
            
            Text("Add vendors to start managing payments")
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
            
            Button {
                showAddVendor = true
            } label: {
                Text("ADD YOUR FIRST VENDOR")
                    .font(.custom("DelaGothicOne-Regular", size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var quickStatsFloating: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Spent")
                    .font(.custom("Spectral-Medium", size: 11))
                    .foregroundColor(.gray)
                Text(formatCurrency(totalSpent))
                    .font(.custom("DelaGothicOne-Regular", size: 16))
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("In Escrow")
                    .font(.custom("Spectral-Medium", size: 11))
                    .foregroundColor(.gray)
                Text(formatCurrency(project.totalAmountInEscrow))
                    .font(.custom("DelaGothicOne-Regular", size: 16))
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Remaining")
                    .font(.custom("Spectral-Medium", size: 11))
                    .foregroundColor(.gray)
                Text(formatCurrency(remainingBudget))
                    .font(.custom("DelaGothicOne-Regular", size: 16))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    private var totalSpent: Double {
        let releasedAmount = project.vendors
            .compactMap { $0.escrow?.milestones }
            .flatMap { $0 }
            .filter { $0.released }
            .reduce(0) { $0 + $1.amountCents }
        return Double(releasedAmount) / 100.0
    }
    
    private var remainingBudget: Double {
        guard let budget = project.totalBudgetDollars else { return 0 }
        return budget - totalSpent - project.totalAmountInEscrow
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Vendor Card

private struct VendorCard: View {
    let vendor: ProjectVendor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section with category badge
            ZStack(alignment: .topLeading) {
                // Placeholder gradient or portfolio image
                if let portfolioUrl = vendor.vendor.portfolioUrls?.first,
                   let url = URL(string: portfolioUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        vendorPlaceholderImage
                    }
                } else {
                    vendorPlaceholderImage
                }
                
                // Status indicator dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                // Category badge
                Text(vendor.role.uppercased())
                    .font(.custom("Spectral-Bold", size: 9))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(12)
            }
            .frame(height: 120)
            .clipped()
            
            // Info section
            VStack(alignment: .leading, spacing: 12) {
                Text(vendor.vendor.name)
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TOTAL")
                            .font(.custom("Spectral-Bold", size: 8))
                            .foregroundColor(.gray)
                        Text(formatCurrency(Double(vendor.amountCents) / 100.0))
                            .font(.custom("DelaGothicOne-Regular", size: 13))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("IN ESCROW")
                            .font(.custom("Spectral-Bold", size: 8))
                            .foregroundColor(.gray)
                        Text(formatCurrency(Double(vendor.escrow?.amountCents ?? 0) / 100.0))
                            .font(.custom("DelaGothicOne-Regular", size: 13))
                    }
                }
                
                // Status pill
                Text(displayStatus.uppercased())
                    .font(.custom("Spectral-Bold", size: 10))
                    .foregroundColor(statusTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(12)
            .background(statusColor.opacity(0.15))
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
    
    private var vendorPlaceholderImage: some View {
        LinearGradient(
            colors: [Color(hex: "E5E5E5"), Color(hex: "C5C5C5")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: iconForRole)
                .font(.custom("Spectral-Regular", size: 28))
                .foregroundColor(.white.opacity(0.6))
        )
    }
    
    private var iconForRole: String {
        let role = vendor.role.lowercased()
        if role.contains("venue") { return "building.2.fill" }
        if role.contains("cater") || role.contains("food") { return "fork.knife" }
        if role.contains("photo") { return "camera.fill" }
        if role.contains("floral") || role.contains("flower") { return "leaf.fill" }
        if role.contains("music") || role.contains("dj") { return "music.note" }
        if role.contains("video") { return "video.fill" }
        return "star.fill"
    }
    
    private var displayStatus: String {
        switch vendor.status {
        case "PENDING", "INVITED": return "Invited"
        case "ACCEPTED": return "Accepted"
        case "PAID": return "Active"
        case "COMPLETED": return "Completed"
        default: return vendor.status
        }
    }
    
    private var statusColor: Color {
        switch vendor.status {
        case "PENDING", "INVITED": return Color(hex: "E9D5FF")
        case "ACCEPTED": return Color(hex: "87CEEB")
        case "PAID": return Color(hex: "BBF7D0")
        case "COMPLETED": return Color(hex: "90EE90")
        default: return .gray
        }
    }
    
    private var statusTextColor: Color {
        switch vendor.status {
        case "PENDING", "INVITED": return Color(hex: "7C3AED")
        case "ACCEPTED": return Color(hex: "4682B4")
        case "PAID": return Color(hex: "228B22")
        case "COMPLETED": return Color(hex: "006400")
        default: return .gray
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Supporting Views

private struct BudgetDonutChart: View {
    let vendors: [ProjectVendor]
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let lineWidth: CGFloat = size * 0.18
            
            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                
                // Center text
                VStack(spacing: 2) {
                    Text("\(vendors.count)")
                        .font(.custom("DelaGothicOne-Regular", size: size * 0.22))
                    Text("vendors")
                        .font(.custom("Spectral-Regular", size: size * 0.1))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: size, height: size)
        }
    }
    
    private var segments: [(start: CGFloat, end: CGFloat, color: Color)] {
        let total = vendors.reduce(0) { $0 + $1.amountCents }
        guard total > 0 else { return [] }
        
        var result: [(start: CGFloat, end: CGFloat, color: Color)] = []
        var currentStart: CGFloat = 0
        
        for vendor in vendors {
            let percentage = CGFloat(vendor.amountCents) / CGFloat(total)
            let end = currentStart + percentage
            result.append((start: currentStart, end: end, color: colorForRole(vendor.role)))
            currentStart = end
        }
        
        return result
    }
    
    private func colorForRole(_ role: String) -> Color {
        let roleLower = role.lowercased()
        if roleLower.contains("venue") { return Color(hex: "E9D5FF") }
        if roleLower.contains("cater") { return Color(hex: "BBF7D0") }
        if roleLower.contains("photo") { return Color(hex: "FF6B35") }
        if roleLower.contains("floral") { return Color(hex: "90EE90") }
        if roleLower.contains("music") || roleLower.contains("dj") { return Color(hex: "FFD700") }
        return Color(hex: "87CEEB")
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String
    let amount: Double
    
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text(label + ":")
                .font(.custom("Spectral-Regular", size: 11))
                .foregroundColor(.gray)
            
            Text(formatCurrency(amount))
                .font(.custom("Spectral-Medium", size: 11))
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

private struct MilestoneRow: View {
    let title: String
    let vendorName: String
    let dueDate: Date?
    var amount: Double? = nil
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Spectral-Bold", size: 14))
                
                Text(vendorName)
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let amount = amount {
                    Text(formatCurrency(amount))
                        .font(.custom("Spectral-Bold", size: 14))
                }
                
                if let dueDate = dueDate {
                    Text(dueDate, style: .date)
                        .font(.custom("Spectral-Regular", size: 11))
                        .foregroundColor(Color(hex: "FF6B35"))
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

private struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.custom("Spectral-Medium", size: 11))
                .foregroundColor(.gray)
            Text(value)
                .font(.custom("DelaGothicOne-Regular", size: 16))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PlaceholderTab: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.custom("Spectral-Regular", size: 48))
                .foregroundColor(.gray.opacity(0.4))
            
            Text(title)
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text("Coming Soon")
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProjectDetailView(
            project: Project(
                id: 1,
                title: "Dream Wedding at The Grove",
                description: "Our perfect day",
                totalBudget: 8500000,
                eventDate: Date().addingTimeInterval(60 * 60 * 24 * 200),
                location: "San Francisco, CA",
                pinterestBoard: nil,
                status: .active,
                customerId: 1,
                customer: User(id: 1, email: "test@test.com", name: "Test User", userType: User.UserType.customer),
                vendors: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}
