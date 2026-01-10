//
//  ProjectsView.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI

struct ProjectsView: View {
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var showCreateProject = false
    @State private var showPastProjects = false

    // Split projects into active and past
    private var activeProjects: [Project] {
        viewModel.allProjects
            .filter { project in
                guard project.myVendorRole == nil else { return false }
                // Past if completed/canceled OR event date has passed
                if project.status == .completed || project.status == .canceled { return false }
                if let eventDate = project.eventDate, eventDate < Date() { return false }
                return true
            }
            .sorted { projectUrgencyScore($0) > projectUrgencyScore($1) } // Most urgent first
    }

    private var pastProjects: [Project] {
        viewModel.allProjects.filter { project in
            guard project.myVendorRole == nil else { return false }
            // Past if completed/canceled OR event date has passed
            if project.status == .completed || project.status == .canceled { return true }
            if let eventDate = project.eventDate, eventDate < Date() { return true }
            return false
        }
    }

    private var vendorProjects: [Project] {
        viewModel.allProjects.filter { $0.myVendorRole != nil }
    }

    // Urgency score for sorting (higher = more urgent)
    private func projectUrgencyScore(_ project: Project) -> Int {
        let now = Date()
        var score = 0

        for vendor in project.vendors {
            guard let escrow = vendor.escrow else { continue }
            for milestone in escrow.milestones where !milestone.released {
                guard let dueDate = milestone.dueDate else { continue }
                let days = Calendar.current.dateComponents([.day], from: now, to: dueDate).day ?? 0
                if days < 0 {
                    score += 1000 + abs(days) // Overdue items get highest priority
                } else if days <= 14 {
                    score += 100 - days // Upcoming items get medium priority
                }
            }
        }
        return score
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Pending Invitations Section
                    if !viewModel.pendingInvitations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PENDING INVITATIONS")
                                .font(.custom("DelaGothicOne-Regular", size: 14))
                                .foregroundColor(Color(hex: "8B5CF6"))
                                .padding(.horizontal)

                            ForEach(viewModel.pendingInvitations) { project in
                                InvitationCard(project: project, viewModel: viewModel)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Active Projects Section
                    VStack(alignment: .leading, spacing: 16) {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, minHeight: 300)
                        } else if let error = viewModel.errorMessage {
                            ErrorView(message: error) {
                                Task { await viewModel.fetchProjects() }
                            }
                        } else if activeProjects.isEmpty && vendorProjects.isEmpty && pastProjects.isEmpty && viewModel.pendingInvitations.isEmpty {
                            EmptyProjectsView {
                                showCreateProject = true
                            }
                        } else if activeProjects.isEmpty && vendorProjects.isEmpty {
                            Text("No active projects")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, minHeight: 60)
                        } else {
                            // Customer active projects
                            ForEach(activeProjects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }

                            // Vendor projects
                            ForEach(vendorProjects) { project in
                                NavigationLink(destination: VendorAgreementView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Past Projects Section (collapsed)
                    if !pastProjects.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showPastProjects.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("Past (\(pastProjects.count))")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)

                                    Spacer()

                                    Image(systemName: showPastProjects ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                            }

                            if showPastProjects {
                                ForEach(pastProjects) { project in
                                    NavigationLink(destination: ProjectDetailView(project: project)) {
                                        ProjectCard(project: project)
                                            .opacity(0.7)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Color("Background"))
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateProject = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .onAppear {
                Task { await viewModel.fetchProjects() }
            }
            .refreshable {
                await viewModel.fetchProjects()
            }
            .sheet(isPresented: $showCreateProject) {
                CreateProjectView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Invitation Card

private struct InvitationCard: View {
    let project: Project
    @ObservedObject var viewModel: ProjectsViewModel
    @State private var isProcessing = false
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.custom("DelaGothicOne-Regular", size: 16))

                    Text("from \(project.customer.name)")
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text("NEW")
                    .font(.custom("Spectral-Bold", size: 10))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "8B5CF6"))
                    .cornerRadius(4)
            }

            // Role and amount
            if let role = project.myVendorRole {
                HStack {
                    Label(role.role, systemImage: "tag.fill")
                        .font(.custom("Spectral-Medium", size: 13))
                        .foregroundColor(.gray)

                    Spacer()

                    Text(role.amountFormatted)
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                }
            }

            // Event date
            if let eventDate = project.eventDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text(eventDate, style: .date)
                        .font(.custom("Spectral-Regular", size: 12))
                }
                .foregroundColor(.gray)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    guard let projectVendorId = project.myVendorRole?.id else { return }
                    isProcessing = true
                    Task {
                        do {
                            try await viewModel.declineAgreement(projectVendorId: projectVendorId)
                        } catch {
                            print("Error declining: \(error)")
                        }
                        isProcessing = false
                    }
                } label: {
                    Text("DECLINE")
                        .font(.custom("Spectral-Bold", size: 12))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(isProcessing)

                Button {
                    guard let projectVendorId = project.myVendorRole?.id else { return }
                    isProcessing = true
                    Task {
                        do {
                            try await viewModel.acceptAgreement(projectVendorId: projectVendorId)
                        } catch {
                            print("Error accepting: \(error)")
                        }
                        isProcessing = false
                    }
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Text("ACCEPT")
                                .font(.custom("Spectral-Bold", size: 12))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "22C55E"))
                    .cornerRadius(8)
                }
                .disabled(isProcessing)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "8B5CF6").opacity(0.3), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .onTapGesture {
            showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            NavigationStack {
                VendorAgreementView(project: project)
            }
        }
    }
}

// MARK: - Stats Row

private struct StatsRow: View {
    let projectCount: Int
    let escrowAmount: Double
    let dueSoon: Int
    
    var body: some View {
        HStack(spacing: 10) {
            StatCard(
                value: "\(projectCount)",
                label: "Projects",
                color: Color(hex: "E9D5FF")
            )
            
            StatCard(
                value: formatEscrow(escrowAmount),
                label: "In Escrow",
                color: Color(hex: "BBF7D0")
            )
            
            StatCard(
                value: "\(dueSoon)",
                label: "Due Soon",
                color: Color(hex: "FED7AA")
            )
        }
    }
    
    private func formatEscrow(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "$%.1fK", amount / 1000)
        }
        return String(format: "$%.0f", amount)
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.custom("DelaGothicOne-Regular", size: 20))
                .foregroundColor(.black)
            
            Text(label)
                .font(.custom("Spectral-Medium", size: 10))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Project Card

private struct ProjectCard: View {
    let project: Project

    // Find the most urgent action item
    private var urgentAction: UrgentAction? {
        var allMilestones: [(milestone: Milestone, vendorName: String)] = []
        for vendor in project.vendors {
            guard let escrow = vendor.escrow else { continue }
            for milestone in escrow.milestones where !milestone.released {
                allMilestones.append((milestone: milestone, vendorName: vendor.vendor.name))
            }
        }

        let now = Date()

        // First priority: overdue milestones
        let overdue = allMilestones
            .filter { item in
                guard let dueDate = item.milestone.dueDate else { return false }
                return dueDate < now
            }
            .sorted { ($0.milestone.dueDate ?? .distantFuture) < ($1.milestone.dueDate ?? .distantFuture) }

        if let first = overdue.first, let dueDate = first.milestone.dueDate {
            let days = Calendar.current.dateComponents([.day], from: dueDate, to: now).day ?? 0
            return UrgentAction(
                description: first.milestone.description ?? "Payment",
                vendorName: first.vendorName,
                timing: "\(days)d overdue",
                isOverdue: true
            )
        }

        // Second priority: upcoming milestones (within 14 days)
        let upcoming = allMilestones
            .filter { item in
                guard let dueDate = item.milestone.dueDate else { return false }
                let days = Calendar.current.dateComponents([.day], from: now, to: dueDate).day ?? 0
                return days >= 0 && days <= 14
            }
            .sorted { ($0.milestone.dueDate ?? .distantFuture) < ($1.milestone.dueDate ?? .distantFuture) }

        if let first = upcoming.first, let dueDate = first.milestone.dueDate {
            let days = Calendar.current.dateComponents([.day], from: now, to: dueDate).day ?? 0
            let timing = days == 0 ? "due today" : "due in \(days)d"
            return UrgentAction(
                description: first.milestone.description ?? "Payment",
                vendorName: first.vendorName,
                timing: timing,
                isOverdue: false
            )
        }

        return nil
    }

    private var hasUrgentItems: Bool {
        urgentAction?.isOverdue == true
    }

    private var hasUpcomingItems: Bool {
        urgentAction != nil && urgentAction?.isOverdue == false
    }

    private var isEmpty: Bool {
        project.vendors.isEmpty && project.totalAmountInEscrow == 0
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar for urgent items
            if hasUrgentItems {
                Rectangle()
                    .fill(Color(hex: "EF4444"))
                    .frame(width: 4)
            }

            VStack(alignment: .leading, spacing: 14) {
                // Header with title
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.custom("DelaGothicOne-Regular", size: 18))
                        .foregroundColor(.black)

                    if let eventDate = project.eventDate {
                        Text(eventDate, style: .date)
                            .font(.custom("Spectral-Regular", size: 13))
                            .foregroundColor(.gray)
                    }
                }

                // Vendor count (or empty prompt)
                if isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8B5CF6"))

                        Text("Add your first vendor to get started")
                            .font(.custom("Spectral-Regular", size: 13))
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                } else {
                    Text("\(project.vendors.count) vendor\(project.vendors.count == 1 ? "" : "s")")
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(.gray)
                }

                // Escrow and budget row - always show, even when $0
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("IN ESCROW")
                            .font(.custom("Spectral-Bold", size: 9))
                            .foregroundColor(.gray)

                        Text(formatCurrency(project.totalAmountInEscrow))
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("BUDGET")
                            .font(.custom("Spectral-Bold", size: 9))
                            .foregroundColor(.gray)

                        Text(formatCurrency(project.totalBudgetDollars ?? 0))
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                            .foregroundColor(.black)
                    }
                }

                // Urgent action or event countdown (only for non-empty projects)
                if !isEmpty {
                    HStack(spacing: 6) {
                        if let action = urgentAction {
                            Image(systemName: action.isOverdue ? "exclamationmark.circle.fill" : "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(action.isOverdue ? Color(hex: "EF4444") : Color(hex: "F59E0B"))

                            Text("\(action.description) · \(action.vendorName) · \(action.timing)")
                                .font(.custom("Spectral-Medium", size: 12))
                                .foregroundColor(action.isOverdue ? Color(hex: "EF4444") : Color(hex: "F59E0B"))
                                .lineLimit(1)
                        } else if let eventDate = project.eventDate {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)

                            Text(eventCountdown(eventDate))
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func eventCountdown(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0 {
            return "Event passed"
        } else if days == 0 {
            return "Event today"
        } else if days == 1 {
            return "Event tomorrow"
        } else if days < 30 {
            return "Event in \(days) days"
        } else {
            let months = days / 30
            return "Event in \(months)mo"
        }
    }
}

// Helper struct for urgent actions
private struct UrgentAction {
    let description: String
    let vendorName: String
    let timing: String
    let isOverdue: Bool
}

// MARK: - Empty State

private struct EmptyProjectsView: View {
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "folder.fill")
                .font(.system(size: 56))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Projects Yet")
                .font(.custom("DelaGothicOne-Regular", size: 22))
            
            Text("Your active projects will appear here")
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: onCreate) {
                Text("CREATE YOUR FIRST PROJECT")
                    .font(.custom("DelaGothicOne-Regular", size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.black)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Something Went Wrong")
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text(message)
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retryAction) {
                Text("TRY AGAIN")
                    .font(.custom("DelaGothicOne-Regular", size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.black)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

#Preview {
    ProjectsView()
}
