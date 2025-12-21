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
    init(project: Project) {
        _viewModel = StateObject(wrappedValue: ProjectDetailViewModel(project: project))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                mainContent
            }
        }
        .background(Color("Background"))
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            Task { await viewModel.refresh() }
        }
    }
    
    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Back button
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14))
                    Text("Back")
                        .font(.custom("Spectral-Medium", size: 14))
                }
                .foregroundColor(.black)
            }

            // Title
            Text(viewModel.project.title)
                .font(.custom("DelaGothicOne-Regular", size: 26))
                .foregroundColor(.black)

            // Date and budget
            HStack(spacing: 16) {
                if let eventDate = viewModel.project.eventDate {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13))
                        Text(eventDate, format: .dateTime.month(.wide).day().year())
                            .font(.custom("Spectral-Regular", size: 14))
                    }
                    .foregroundColor(.gray)
                }

                if let budget = viewModel.project.totalBudgetDollars {
                    HStack(spacing: 5) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 13))
                        Text(formatCurrency(budget))
                            .font(.custom("Spectral-Regular", size: 14))
                    }
                    .foregroundColor(.gray)
                }

                if let location = viewModel.project.location {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin")
                            .font(.system(size: 13))
                        Text(location)
                            .font(.custom("Spectral-Regular", size: 14))
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 10)
    }
    
    // MARK: - Main Content

    @State private var showAddVendor = false

    private var mainContent: some View {
        VStack(spacing: 28) {
            // Vendors
            vendorsSection

            // Milestones (only if there are any)
            if hasUpcomingMilestones {
                milestonesSection
            }

            // RFP link
            rfpSection

            Spacer(minLength: 40)
        }
        .padding(.horizontal)
        .sheet(isPresented: $showAddVendor, onDismiss: {
            Task { await viewModel.refresh() }
        }) {
            AddVendorView(project: viewModel.project)
        }
    }

    // MARK: - Vendors Section

    private var vendorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vendors")
                    .font(.custom("DelaGothicOne-Regular", size: 20))

                Spacer()

                Button {
                    showAddVendor = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add")
                            .font(.custom("Spectral-Medium", size: 13))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "FFD700"))
                    .cornerRadius(8)
                }
            }

            if viewModel.project.vendors.isEmpty {
                VStack(spacing: 12) {
                    Text("No vendors yet")
                        .font(.custom("Spectral-Regular", size: 15))
                        .foregroundColor(.gray)
                    Text("Add your first vendor to get started")
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.white)
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.project.vendors) { vendor in
                        NavigationLink(destination: VendorDetailView(projectVendor: vendor)) {
                            SimpleVendorRow(vendor: vendor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Milestones Section

    private var hasUpcomingMilestones: Bool {
        !upcomingMilestones.isEmpty
    }

    private var upcomingMilestones: [(milestone: Milestone, vendorName: String)] {
        viewModel.project.vendors
            .flatMap { vendor in
                (vendor.escrow?.milestones ?? [])
                    .filter { !$0.released }
                    .map { (milestone: $0, vendorName: vendor.vendor.name) }
            }
            .sorted { ($0.milestone.dueDate ?? .distantFuture) < ($1.milestone.dueDate ?? .distantFuture) }
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Coming up")
                .font(.custom("DelaGothicOne-Regular", size: 18))

            VStack(spacing: 10) {
                ForEach(upcomingMilestones.prefix(4), id: \.milestone.id) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.milestone.description ?? "Payment")
                                .font(.custom("Spectral-Medium", size: 14))
                            Text(item.vendorName)
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(formatCurrency(Double(item.milestone.amountCents) / 100.0))
                                .font(.custom("Spectral-Bold", size: 14))

                            if let due = item.milestone.dueDate {
                                Text(formatDueDate(due))
                                    .font(.custom("Spectral-Regular", size: 11))
                                    .foregroundColor(dueDateColor(due))
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(10)
                }
            }
        }
    }

    private func formatDueDate(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0 {
            return "\(abs(days))d overdue"
        } else if days == 0 {
            return "Due today"
        } else if days <= 7 {
            return "Due in \(days)d"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0 {
            return Color(hex: "EF4444")
        } else if days <= 7 {
            return Color(hex: "F59E0B")
        } else {
            return .gray
        }
    }

    // MARK: - RFP Section

    private var rfpSection: some View {
        NavigationLink(destination: RFPListView(projectId: viewModel.project.id)) {
            HStack(spacing: 14) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "8B5CF6"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Find more vendors")
                        .font(.custom("Spectral-Medium", size: 15))
                        .foregroundColor(.black)
                    Text("Post an RFP and get quotes")
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Simple Vendor Row

private struct SimpleVendorRow: View {
    let vendor: ProjectVendor

    private var statusText: String {
        switch vendor.status {
        case "PENDING", "INVITED":
            return "Waiting for response"
        case "ACCEPTED":
            if let escrow = vendor.escrow, escrow.status == "PENDING" {
                return "Ready to fund"
            }
            return "Accepted"
        case "PAID":
            return "In progress"
        case "COMPLETED":
            return "Done"
        default:
            return vendor.status.lowercased()
        }
    }

    private var statusColor: Color {
        switch vendor.status {
        case "PENDING", "INVITED":
            return Color(hex: "8B5CF6")
        case "ACCEPTED":
            if let escrow = vendor.escrow, escrow.status == "PENDING" {
                return Color(hex: "F59E0B")
            }
            return Color(hex: "3B82F6")
        case "PAID", "COMPLETED":
            return Color(hex: "22C55E")
        default:
            return .gray
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Role icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: iconForRole)
                    .font(.system(size: 18))
                    .foregroundColor(statusColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(vendor.vendor.name)
                    .font(.custom("Spectral-Medium", size: 15))
                    .foregroundColor(.black)

                HStack(spacing: 6) {
                    Text(vendor.role)
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)

                    Text("·")
                        .foregroundColor(.gray)

                    Text(statusText)
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(statusColor)
                }
            }

            Spacer()

            // Amount
            Text(formatCurrency(Double(vendor.amountCents) / 100.0))
                .font(.custom("DelaGothicOne-Regular", size: 15))
                .foregroundColor(.black)

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
    }

    private var iconForRole: String {
        let role = vendor.role.lowercased()
        if role.contains("venue") { return "building.2" }
        if role.contains("cater") || role.contains("food") { return "fork.knife" }
        if role.contains("photo") { return "camera" }
        if role.contains("floral") || role.contains("flower") { return "leaf" }
        if role.contains("music") || role.contains("dj") { return "music.note" }
        if role.contains("video") { return "video" }
        if role.contains("cake") || role.contains("bakery") { return "birthday.cake" }
        if role.contains("hair") || role.contains("makeup") { return "sparkles" }
        return "star"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
                updatedAt: Date(),
                myVendorRole: nil
            )
        )
    }
}
