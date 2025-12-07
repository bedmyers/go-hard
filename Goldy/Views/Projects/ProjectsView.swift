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
                    StatsRow(
                        projectCount: viewModel.totalProjects,
                        escrowAmount: viewModel.totalInEscrow,
                        dueSoon: viewModel.projectsDueSoon
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
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
                        } else if viewModel.allProjects.isEmpty {
                            EmptyProjectsView {
                                showCreateProject = true
                            }
                        } else {
                            ForEach(viewModel.allProjects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
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
            .task {
                await viewModel.fetchProjects()
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
                .font(.system(size: 10, weight: .medium))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                if let imageURL = project.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        projectGradient
                    }
                } else {
                    projectGradient
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                        .foregroundColor(.white)
                    
                    if let eventDate = project.eventDate {
                        Text(eventDate, style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
            .frame(height: 140)
            .clipped()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(project.vendors.count) vendors")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(project.progressPercentage)%")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.black)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(project.statusColor)
                            .frame(width: geometry.size.width * CGFloat(project.progressPercentage) / 100, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("IN ESCROW")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Text(formatCurrency(project.totalAmountInEscrow))
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                    }
                    
                    Spacer()
                    
                    if let totalBudget = project.totalBudgetDollars {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("TOTAL BUDGET")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            Text(formatCurrency(totalBudget))
                                .font(.custom("DelaGothicOne-Regular", size: 16))
                        }
                    }
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(project.statusColor)
                        .font(.system(size: 14))
                    
                    Text(project.nextMilestone)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(project.statusColor.opacity(0.2))
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    private var projectGradient: some View {
        LinearGradient(
            colors: [Color(hex: "3A3A3A"), Color(hex: "5A5A5A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "heart.fill")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.2))
        )
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
                .font(.system(size: 14))
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
                .font(.system(size: 14))
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
