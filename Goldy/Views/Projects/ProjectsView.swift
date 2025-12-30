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

                    // Projects Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("YOUR PROJECTS")
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                            .padding(.horizontal)

                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, minHeight: 300)
                        } else if let error = viewModel.errorMessage {
                            ErrorView(message: error) {
                                Task { await viewModel.fetchProjects() }
                            }
                        } else if viewModel.allProjects.isEmpty && viewModel.pendingInvitations.isEmpty {
                            EmptyProjectsView {
                                showCreateProject = true
                            }
                        } else if viewModel.allProjects.isEmpty {
                            Text("No active projects yet")
                                .font(.custom("Spectral-Regular", size: 14))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, minHeight: 100)
                        } else {
                            ForEach(Array(viewModel.allProjects.enumerated()), id: \.element.id) { index, project in
                                // Route vendors to their agreement view, customers to full project view
                                if project.myVendorRole != nil {
                                    NavigationLink(destination: VendorAgreementView(project: project)) {
                                        ProjectCard(project: project, colorIndex: index)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                } else {
                                    NavigationLink(destination: ProjectDetailView(project: project)) {
                                        ProjectCard(project: project, colorIndex: index)
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
                            .font(.custom("Spectral-Bold", size: 18))
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
    let colorIndex: Int

    private static let cardColors: [Color] = [
        Color(hex: "FFD700"), // Gold
        Color(hex: "8B5CF6"), // Purple
        Color(hex: "FF6B35"), // Orange
        Color(hex: "22C55E"), // Green
        Color(hex: "3B82F6"), // Blue
        Color(hex: "E60023"), // Pinterest Red
    ]

    private var cardColor: Color {
        Self.cardColors[colorIndex % Self.cardColors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and date
            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(.custom("DelaGothicOne-Regular", size: 18))
                    .foregroundColor(.black)

                if let eventDate = project.eventDate {
                    Text(eventDate, style: .date)
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(.black.opacity(0.6))
                }
            }

            // Progress section
            HStack {
                Text("\(project.vendors.count) vendors")
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.black.opacity(0.6))

                Spacer()

                Text("\(project.progressPercentage)%")
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .foregroundColor(.black)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: geometry.size.width * CGFloat(project.progressPercentage) / 100, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)

            // Escrow and budget
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IN ESCROW")
                        .font(.custom("Spectral-Bold", size: 9))
                        .foregroundColor(.black.opacity(0.5))

                    Text(formatCurrency(project.totalAmountInEscrow))
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                        .foregroundColor(.black)
                }

                Spacer()

                if let totalBudget = project.totalBudgetDollars {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("TOTAL BUDGET")
                            .font(.custom("Spectral-Bold", size: 9))
                            .foregroundColor(.black.opacity(0.5))

                        Text(formatCurrency(totalBudget))
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                            .foregroundColor(.black)
                    }
                }
            }

            // Next milestone
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.black.opacity(0.6))
                    .font(.custom("Spectral-Regular", size: 14))

                Text(project.nextMilestone)
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.black.opacity(0.6))
            }
        }
        .padding(16)
        .background(cardColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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
