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
                        VStack(alignment: .leading, spacing: 8) {
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
                    VStack(alignment: .leading, spacing: 8) {
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
                        VStack(alignment: .leading, spacing: 8) {
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
        HStack(spacing: 0) {
            // Purple accent bar on left
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "8B5CF6"))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                // Row 1: Project name + amount
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.title)
                            .font(.custom("Spectral-Bold", size: 16))
                            .foregroundColor(.black)

                        Text("from \(project.customer.name)")
                            .font(.custom("Spectral-Medium", size: 13))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    if let role = project.myVendorRole {
                        Text(role.amountFormatted)
                            .font(.custom("Spectral-Bold", size: 18))
                            .foregroundColor(.black)
                    }
                }

                // Row 2: Role + event date
                if let role = project.myVendorRole {
                    HStack(spacing: 0) {
                        Text(role.role)
                            .font(.custom("Spectral-Medium", size: 13))
                            .foregroundColor(.black)

                        if let eventDate = project.eventDate {
                            Text(" · ")
                                .foregroundColor(.black)

                            Text(eventDate, style: .date)
                                .font(.custom("Spectral-Medium", size: 13))
                                .foregroundColor(.black)
                        }
                    }
                }

                // Action buttons
                HStack(spacing: 8) {
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
                        Text("Decline")
                            .font(.custom("Spectral-Medium", size: 13))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
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
                                Text("Accept")
                                    .font(.custom("Spectral-Medium", size: 13))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "22C55E"))
                        .cornerRadius(6)
                    }
                    .disabled(isProcessing)
                }
            }
            .padding(14)
        }
        .background(Color.white)
        .cornerRadius(10)
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
    }
}

// MARK: - Project Card

private struct ProjectCard: View {
    let project: Project

    // Calculate escrow progress as percentage of budget
    private var escrowProgress: Double {
        guard let budget = project.totalBudgetDollars, budget > 0 else { return 0 }
        return min(project.totalAmountInEscrow / budget, 1.0)
    }

    // Check for overdue milestones
    private var hasOverdueItems: Bool {
        let now = Date()
        for vendor in project.vendors {
            guard let escrow = vendor.escrow else { continue }
            for milestone in escrow.milestones where !milestone.released {
                if let dueDate = milestone.dueDate, dueDate < now {
                    return true
                }
            }
        }
        return false
    }

    // Format date with ordinal suffix
    private func formatDate(_ date: Date) -> String {
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

    // Format escrow amount compactly
    private func formatCompact(_ amount: Double) -> String {
        if amount >= 1000 {
            return "$\(Int(amount / 1000))k held"
        } else {
            return "$\(Int(amount)) held"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Row 1: Project name + Budget
            HStack(alignment: .top) {
                Text(project.title)
                    .font(.custom("Spectral-Bold", size: 16))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Spacer()

                Text(formatCurrency(project.totalBudgetDollars ?? 0))
                    .font(.custom("Spectral-Bold", size: 18))
                    .foregroundColor(.black)
            }

            // Row 2: Progress bar (escrow/budget ratio)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 10)

                    if escrowProgress > 0 {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: "EC633A").opacity(0.3))
                            .frame(width: geometry.size.width * escrowProgress, height: 10)
                    }
                }
            }
            .frame(height: 10)

            // Row 3: Date + vendor count + escrow held (+ overdue indicator)
            HStack(spacing: 0) {
                if let eventDate = project.eventDate {
                    Text(formatDate(eventDate))
                        .font(.custom("Spectral-Medium", size: 13))
                        .foregroundColor(.black)

                    Text(" · ")
                        .foregroundColor(.black)
                }

                Text("\(project.vendors.count) vendor\(project.vendors.count == 1 ? "" : "s")")
                    .font(.custom("Spectral-Medium", size: 13))
                    .foregroundColor(.black)

                Text(" · ")
                    .foregroundColor(.black)

                Text(formatCompact(project.totalAmountInEscrow))
                    .font(.custom("Spectral-Medium", size: 13))
                    .foregroundColor(.black)

                if hasOverdueItems {
                    Text(" · ")
                        .foregroundColor(.black)

                    Text("overdue")
                        .font(.custom("Spectral-Medium", size: 13))
                        .foregroundColor(Color(hex: "EF4444"))
                }
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
                .font(.custom("Spectral-Regular", size: 16))
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
