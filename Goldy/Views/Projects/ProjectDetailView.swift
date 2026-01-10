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
    @State private var showEditProject = false
    @State private var showDeleteConfirm = false
    @State private var showMoreMenu = false

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
        .sheet(isPresented: $showEditProject, onDismiss: {
            Task { await viewModel.refresh() }
        }) {
            EditProjectView(project: viewModel.project)
        }
        .confirmationDialog("Project Options", isPresented: $showMoreMenu) {
            Button("Edit Project") {
                showEditProject = true
            }
            Button("Archive Project", role: .destructive) {
                showDeleteConfirm = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Archive Project?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Archive", role: .destructive) {
                Task {
                    await viewModel.archiveProject()
                    dismiss()
                }
            }
        } message: {
            Text("This will move the project to your past projects. You can still view it there.")
        }
    }
    
    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Nav row with back and more buttons
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Color("Background"))
                        .clipShape(Circle())
                }

                Spacer()

                Button {
                    showMoreMenu = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Color("Background"))
                        .clipShape(Circle())
                }
            }

            // Title
            Text(viewModel.project.title)
                .font(.custom("DelaGothicOne-Regular", size: 26))
                .foregroundColor(.black)

            // Date, budget, location
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

            // Payments (only if there are any)
            if hasPayments {
                paymentsSection
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
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add")
                            .font(.custom("Spectral-Medium", size: 13))
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
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

    // MARK: - Payments Section

    private var hasPayments: Bool {
        !allMilestones.isEmpty
    }

    // All milestones (both paid and unpaid)
    // Sorted: overdue first, then upcoming by date, then completed at end
    private var allMilestones: [(milestone: Milestone, vendorName: String, vendorId: Int)] {
        let now = Date()
        return viewModel.project.vendors
            .flatMap { vendor in
                (vendor.escrow?.milestones ?? [])
                    .map { (milestone: $0, vendorName: vendor.vendor.name, vendorId: vendor.id) }
            }
            .sorted { item1, item2 in
                let m1 = item1.milestone
                let m2 = item2.milestone

                // Completed items go last
                if m1.released != m2.released {
                    return !m1.released
                }

                // Both completed - sort by due date
                if m1.released && m2.released {
                    return (m1.dueDate ?? .distantPast) > (m2.dueDate ?? .distantPast)
                }

                // Both unpaid - overdue first, then by due date
                let d1 = m1.dueDate ?? .distantFuture
                let d2 = m2.dueDate ?? .distantFuture
                let isOverdue1 = d1 < now
                let isOverdue2 = d2 < now

                if isOverdue1 != isOverdue2 {
                    return isOverdue1 // Overdue items first
                }

                // Both overdue or both upcoming - sort by date
                if isOverdue1 {
                    return d1 < d2 // Most overdue first
                }
                return d1 < d2 // Soonest upcoming first
            }
    }

    // Payment summary calculations
    private var totalPaid: Double {
        allMilestones
            .filter { $0.milestone.released }
            .reduce(0) { $0 + Double($1.milestone.amountCents) / 100.0 }
    }

    private var totalInEscrow: Double {
        viewModel.project.totalAmountInEscrow
    }

    private var totalRemaining: Double {
        allMilestones
            .filter { !$0.milestone.released }
            .reduce(0) { $0 + Double($1.milestone.amountCents) / 100.0 }
    }

    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Payments")
                .font(.custom("DelaGothicOne-Regular", size: 20))

            // Payment summary line
            HStack(spacing: 4) {
                Text(formatCurrency(totalPaid))
                    .font(.custom("Spectral-Bold", size: 13))
                    .foregroundColor(Color(hex: "22C55E"))
                Text("paid")
                    .font(.custom("Spectral-Regular", size: 13))
                    .foregroundColor(.gray)
                Text("·")
                    .foregroundColor(.gray)
                Text(formatCurrency(totalInEscrow))
                    .font(.custom("Spectral-Bold", size: 13))
                    .foregroundColor(Color(hex: "3B82F6"))
                Text("in escrow")
                    .font(.custom("Spectral-Regular", size: 13))
                    .foregroundColor(.gray)
                Text("·")
                    .foregroundColor(.gray)
                Text(formatCurrency(totalRemaining))
                    .font(.custom("Spectral-Bold", size: 13))
                    .foregroundColor(.black)
                Text("remaining")
                    .font(.custom("Spectral-Regular", size: 13))
                    .foregroundColor(.gray)
            }

            VStack(spacing: 10) {
                ForEach(allMilestones, id: \.milestone.id) { item in
                    // Find the vendor for navigation
                    if let vendor = viewModel.project.vendors.first(where: { $0.id == item.vendorId }) {
                        NavigationLink(destination: VendorDetailView(projectVendor: vendor)) {
                            PaymentRow(
                                milestone: item.milestone,
                                vendorName: item.vendorName
                            )
                        }
                        .buttonStyle(.plain)
                    }
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

// MARK: - Payment Row

private struct PaymentRow: View {
    let milestone: Milestone
    let vendorName: String

    private var isPaid: Bool {
        milestone.released
    }

    // Auto-release countdown - customer has 3 days after due date
    private var autoReleaseInfo: (daysLeft: Int, isOverdue: Bool)? {
        guard !isPaid, let dueDate = milestone.dueDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        if days < 0 {
            // Overdue - show countdown to auto-release (3 days after due)
            let daysOverdue = abs(days)
            let daysUntilAutoRelease = 3 - daysOverdue
            if daysUntilAutoRelease > 0 {
                return (daysUntilAutoRelease, true)
            } else if daysUntilAutoRelease == 0 {
                return (0, true) // Auto-releases today
            }
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left side - checkmark for paid, exclamation for overdue
            if isPaid {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "22C55E"))
            } else if autoReleaseInfo?.isOverdue == true {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "EF4444"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(milestone.description ?? "Payment")
                    .font(.custom("Spectral-Medium", size: 14))
                    .foregroundColor(isPaid ? .gray : .black)
                Text(vendorName)
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Text(formatCurrency(Double(milestone.amountCents) / 100.0))
                        .font(.custom("Spectral-Bold", size: 14))
                        .foregroundColor(isPaid ? .gray : .black)

                    if isPaid {
                        Text("Paid")
                            .font(.custom("Spectral-Medium", size: 11))
                            .foregroundColor(Color(hex: "22C55E"))
                    }
                }

                if let dueDate = milestone.dueDate {
                    if isPaid {
                        Text("Completed")
                            .font(.custom("Spectral-Regular", size: 11))
                            .foregroundColor(.gray)
                    } else if let autoRelease = autoReleaseInfo {
                        if autoRelease.daysLeft == 0 {
                            Text("Auto-releases today")
                                .font(.custom("Spectral-Medium", size: 11))
                                .foregroundColor(Color(hex: "EF4444"))
                        } else {
                            Text("Auto-releases in \(autoRelease.daysLeft)d")
                                .font(.custom("Spectral-Medium", size: 11))
                                .foregroundColor(Color(hex: "EF4444"))
                        }
                    } else {
                        Text(formatDueDate(dueDate))
                            .font(.custom("Spectral-Regular", size: 11))
                            .foregroundColor(dueDateColor(dueDate))
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.4))
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(10)
        .opacity(isPaid ? 0.7 : 1.0)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
}

// MARK: - Simple Vendor Row

private struct SimpleVendorRow: View {
    let vendor: ProjectVendor

    // Calculate payment progress
    private var paymentProgress: (paid: Int, total: Int)? {
        guard let escrow = vendor.escrow else { return nil }
        let milestones = escrow.milestones
        guard !milestones.isEmpty else { return nil }
        let paid = milestones.filter { $0.released }.count
        return (paid, milestones.count)
    }

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
            // Show specific payment progress
            if let progress = paymentProgress {
                if progress.paid == 0 {
                    return "Deposit pending"
                } else if progress.paid < progress.total {
                    return "\(progress.paid) of \(progress.total) paid"
                } else {
                    return "Fully paid"
                }
            }
            return "In progress"
        case "COMPLETED":
            return "Completed"
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
        case "PAID":
            if let progress = paymentProgress, progress.paid == progress.total {
                return Color(hex: "22C55E")
            }
            return Color(hex: "3B82F6")
        case "COMPLETED":
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
