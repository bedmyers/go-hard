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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.project.title)
                    .font(.custom("DelaGothicOne-Regular", size: 30))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showEditProject = true
                    } label: {
                        Label("Edit Project", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Archive Project", systemImage: "archivebox")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
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
        VStack(alignment: .leading, spacing: 8) {
            // Date, budget, location - simple text, no icons
            HStack(spacing: 16) {
                if let eventDate = viewModel.project.eventDate {
                    Text(formatDateShort(eventDate))
                        .font(.custom("Spectral-Regular", size: 16))
                        .foregroundColor(.black)
                }

                if let budget = viewModel.project.totalBudgetDollars {
                    Text(formatCurrency(budget))
                        .font(.custom("Spectral-Regular", size: 16))
                        .foregroundColor(.black)
                }

                if let location = viewModel.project.location {
                    Text(location)
                        .font(.custom("Spectral-Regular", size: 16))
                        .foregroundColor(.black)
                }
            }

            // Pagination dots
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let month = formatter.string(from: date)

        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: date)

        return "\(month) \(day)\(suffix), \(year)"
    }
    
    // MARK: - Main Content

    @State private var showAddVendor = false

    private var mainContent: some View {
        VStack(spacing: 16) {
            // Budget Summary
            budgetSummarySection

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

    // MARK: - Budget Summary Section

    private var totalUnderContract: Double {
        Double(viewModel.project.vendors.reduce(0) { $0 + $1.amountCents }) / 100.0
    }

    private var totalInEscrowAmount: Double {
        viewModel.project.vendors.reduce(0.0) { total, vendor in
            guard let escrow = vendor.escrow,
                  escrow.status == "FUNDED" || escrow.status == "AUTHORIZED" else { return total }
            let unreleasedAmount = escrow.milestones
                .filter { !$0.released }
                .reduce(0) { $0 + $1.amountCents }
            return total + Double(unreleasedAmount) / 100.0
        }
    }

    private var totalReleasedAmount: Double {
        viewModel.project.vendors.reduce(0.0) { total, vendor in
            guard let escrow = vendor.escrow else { return total }
            let releasedAmount = escrow.milestones
                .filter { $0.released }
                .reduce(0) { $0 + $1.amountCents }
            return total + Double(releasedAmount) / 100.0
        }
    }

    // MARK: - Budget Summary Section

    private var budgetSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Total budget bar (fully filled)
            BudgetProgressRow(
                label: "Total budget",
                amount: viewModel.project.totalBudgetDollars ?? 0,
                totalBudget: viewModel.project.totalBudgetDollars ?? 0,
                fillColor: Color(red: 224/255, green: 212/255, blue: 181/255, opacity: 1) // beige
            )

            // Budget breakdown rows - horizontal progress bars
            BudgetProgressRow(
                label: "Total under contract",
                amount: totalUnderContract,
                totalBudget: viewModel.project.totalBudgetDollars ?? 0,
                fillColor: Color(red: 236/255, green: 99/255, blue: 58/255, opacity: 0.3) // orange 30%
            )

            BudgetProgressRow(
                label: "Total in escrow",
                amount: totalInEscrowAmount,
                totalBudget: viewModel.project.totalBudgetDollars ?? 0,
                fillColor: Color(red: 153/255, green: 180/255, blue: 238/255, opacity: 0.5) // blue 50%
            )

            BudgetProgressRow(
                label: "Total released",
                amount: totalReleasedAmount,
                totalBudget: viewModel.project.totalBudgetDollars ?? 0,
                fillColor: Color(red: 214/255, green: 160/255, blue: 184/255, opacity: 0.5) // pink 50%
            )
        }
        .padding(.bottom, 28) // Extra spacing before vendor cards (40 total with VStack spacing)
    }

    // MARK: - Vendors Section

    private let defaultCategories = ["Venue", "Photographer", "Catering", "Florist", "DJ/Music", "Videographer", "Cake", "Hair & Makeup", "Wedding Planner"]

    private var bookedCategories: Set<String> {
        Set(viewModel.project.vendors.map { $0.role })
    }

    private var unbookedCategories: [String] {
        defaultCategories.filter { !bookedCategories.contains($0) }
    }

    private var vendorsSection: some View {
        VStack(spacing: 8) {
            // Booked vendors
            ForEach(viewModel.project.vendors) { vendor in
                NavigationLink(destination: VendorDetailView(projectVendor: vendor)) {
                    VendorCard(vendor: vendor)
                }
                .buttonStyle(.plain)
            }

            // Empty vendor slots
            ForEach(unbookedCategories, id: \.self) { category in
                Button {
                    showAddVendor = true
                } label: {
                    EmptyVendorCard(category: category, estimate: getEstimate(for: category))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // Placeholder - replace with actual estimates from your data model
    private func getEstimate(for category: String) -> Double? {
        // TODO: Pull from actual budget estimates
        let estimates: [String: Double] = [
            "Photographer": 16000,
            "Wedding Planner": 14455
        ]
        return estimates[category]
    }

    // MARK: - Payments Section

    private var hasPayments: Bool {
        !allMilestones.isEmpty
    }

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

                if m1.released != m2.released {
                    return !m1.released
                }

                if m1.released && m2.released {
                    return (m1.dueDate ?? .distantPast) > (m2.dueDate ?? .distantPast)
                }

                let d1 = m1.dueDate ?? .distantFuture
                let d2 = m2.dueDate ?? .distantFuture
                let isOverdue1 = d1 < now
                let isOverdue2 = d2 < now

                if isOverdue1 != isOverdue2 {
                    return isOverdue1
                }

                if isOverdue1 {
                    return d1 < d2
                }
                return d1 < d2
            }
    }

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

    // MARK: - RFP Section

    private var rfpSection: some View {
        NavigationLink(destination: RFPListView(projectId: viewModel.project.id)) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Find more vendors")
                    .font(.custom("Spectral-SemiBold", size: 15))
                    .foregroundColor(.black)
                Text("Post an RFP and get quotes →")
                    .font(.custom("Spectral-Regular", size: 13))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Budget Progress Row

private struct BudgetProgressRow: View {
    let label: String
    let amount: Double
    let totalBudget: Double
    let fillColor: Color

    private var fillPercentage: Double {
        guard totalBudget > 0 else { return 0 }
        return min(amount / totalBudget, 1.0) // Cap at 100%
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar (very light, almost invisible)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.08))

                // Filled portion
                RoundedRectangle(cornerRadius: 6)
                    .fill(fillColor)
                    .frame(width: max(geometry.size.width * fillPercentage, 0))

                // Text overlay - inside the bar
                HStack {
                    Text(label)
                        .font(.custom("Spectral-Medium", size: 16))
                        .foregroundColor(.black)

                    Spacer()

                    Text(formatCurrency(amount))
                        .font(.custom("Spectral-Bold", size: 16))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
            }
        }
        .frame(height: 68)
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

    private var paymentProgress: Double {
        guard let escrow = vendor.escrow else { return 0 }
        let milestones = escrow.milestones
        guard !milestones.isEmpty else { return 0 }
        let releasedAmount = milestones.filter { $0.released }.reduce(0) { $0 + $1.amountCents }
        let totalAmount = milestones.reduce(0) { $0 + $1.amountCents }
        guard totalAmount > 0 else { return 0 }
        return Double(releasedAmount) / Double(totalAmount)
    }

    private var statusText: String {
        guard let escrow = vendor.escrow else {
            switch vendor.status {
            case "PENDING", "INVITED":
                return "Pending"
            case "ACCEPTED":
                return "Awaiting deposit"
            default:
                return vendor.status.capitalized
            }
        }

        let releasedMilestones = escrow.milestones.filter { $0.released }
        let totalMilestones = escrow.milestones.count

        if releasedMilestones.count == totalMilestones && totalMilestones > 0 {
            return "Fully Paid"
        } else if releasedMilestones.isEmpty {
            if escrow.status == "FUNDED" || escrow.status == "AUTHORIZED" {
                return "Deposit in escrow"
            }
            return "Awaiting deposit"
        } else {
            return "Deposit released"
        }
    }
    
    private var progressBarColor: Color {
        guard let escrow = vendor.escrow else {
            return Color.gray.opacity(0.2)
        }
        
        let releasedMilestones = escrow.milestones.filter { $0.released }
        let totalMilestones = escrow.milestones.count
        
        if releasedMilestones.count == totalMilestones && totalMilestones > 0 {
            return Color(hex: "22C55E") // green - fully paid
        } else if escrow.status == "FUNDED" || escrow.status == "AUTHORIZED" {
            return Color(hex: "3B82F6") // blue - in escrow
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    // Show some progress even if 0 to indicate the bar exists
    private var displayProgress: Double {
        if paymentProgress > 0 {
            return paymentProgress
        }
        // Show a sliver for "in escrow" state
        if let escrow = vendor.escrow,
           escrow.status == "FUNDED" || escrow.status == "AUTHORIZED" {
            return 0.5
        }
        return 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Row 1: Name and Amount
            HStack(alignment: .top) {
                Text(vendor.vendor.name)
                    .font(.custom("Spectral-Bold", size: 16))
                    .foregroundColor(.black)

                Spacer()

                Text(formatCurrency(Double(vendor.amountCents) / 100.0))
                    .font(.custom("Spectral-Bold", size: 18))
                    .foregroundColor(.black)
            }

            // Row 2: Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 10)

                    if displayProgress > 0 {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: "E0D4B5")) // beige fill color
                            .frame(width: geometry.size.width * displayProgress, height: 10)
                    }
                }
            }
            .frame(height: 10)

            // Row 3: Category | Status
            Text("\(vendor.role) | \(statusText)")
                .font(.custom("Spectral-Medium", size: 13))
                .foregroundColor(.black)
        }
        .padding(14)
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

// MARK: - Empty Vendor Card

private struct EmptyVendorCard: View {
    let category: String
    let estimate: Double?

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.custom("Spectral-Medium", size: 15))
                    .foregroundColor(.black)

                Text("Add your vendor →")
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            if let estimate = estimate {
                Text("Estimate: \(formatCurrency(estimate))")
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(4)
            }
        }
        .padding(14)
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

// MARK: - Payment Row

private struct PaymentRow: View {
    let milestone: Milestone
    let vendorName: String

    private var isPaid: Bool {
        milestone.released
    }

    private var autoReleaseInfo: (daysLeft: Int, isOverdue: Bool)? {
        guard !isPaid, let dueDate = milestone.dueDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        if days < 0 {
            let daysOverdue = abs(days)
            let daysUntilAutoRelease = 3 - daysOverdue
            if daysUntilAutoRelease > 0 {
                return (daysUntilAutoRelease, true)
            } else if daysUntilAutoRelease == 0 {
                return (0, true)
            }
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
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

// MARK: - Preview

#Preview {
    NavigationStack {
        ProjectDetailView(
            project: Project(
                id: 1,
                title: "B&C's Wedding",
                description: "Our perfect day",
                totalBudget: 20000000,
                eventDate: Date().addingTimeInterval(60 * 60 * 24 * 200),
                location: "Book Tower Conservatory",
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
