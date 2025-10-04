//
//  OpenEscrowsView.swift
//  Goldy
//
//  Created by Blair Myers on 3/5/25.
//

import SwiftUI

enum ViewMode {
    case stack, grid
}

struct OpenEscrowsView: View {
    @ObservedObject var viewModel: EscrowViewModel
    @State private var selectedEscrow: EscrowDetail? = nil
    @State private var showCreateEscrow = false
    @State private var viewMode: ViewMode = .stack
    @AppStorage("authToken") private var authToken: String = ""

    private let baseFrontHeight: CGFloat = 300
    private let heightIncrement: CGFloat = 32
    private let heightIncrementAfter4: CGFloat = 12
    private let spacing: CGFloat = 70
    
    var body: some View {
        Group {
            if viewModel.isLoading && !viewModel.hasLoadedOnce {
                loadingState
            } else if viewModel.projects.isEmpty {
                GetStartedView(viewModel: viewModel)
            } else {
                escrowsContent
            }
        }
        .onAppear {
            loadEscrowsIfNeeded()
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.black)
            
            Text("Loading escrows...")
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .foregroundColor(.black)
                .opacity(0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.97, green: 0.93, blue: 0.85).ignoresSafeArea())
    }
    
    private var escrowsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            
            if viewMode == .stack {
                stackView
            } else {
                gridView
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.97, green: 0.93, blue: 0.85),
                    Color(red: 0.99, green: 0.90, blue: 0.90)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showCreateEscrow) {
            CreateEscrowFlowView(viewModel: viewModel, onComplete: {
                viewModel.loadEscrows(token: authToken)
                showCreateEscrow = false
            })
        }
        .sheet(item: $selectedEscrow) { escrow in
            EscrowDetailView(escrowId: escrow.id)
        }
    }
    
    private var stackView: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .bottom) {
                ForEach(Array(viewModel.projects.enumerated()), id: \.element.id) { i, project in
                    let heightAdded = i <= 3 ? heightIncrement : heightIncrementAfter4
                    let heightForThisCard = baseFrontHeight + (CGFloat(i) * heightAdded)
                    let cardColorIndex = (i % 7) + 1
                    let cardColorName = "Card\(cardColorIndex)"
                    
                    EscrowCardView(
                        title: project.title,
                        subtitle: project.subtitle ?? "",
                        progress: project.progress,
                        totalCommitted: project.totalCommitted,
                        cardColorName: cardColorName,
                        milestones: createMilestoneDisplays(for: project)
                    )
                    .frame(height: heightForThisCard)
                    .offset(y: -CGFloat(i) * spacing)
                    .zIndex(Double(viewModel.projects.count - i))
                    .onTapGesture {
                        selectedEscrow = mockEscrowDetail(from: project)
                    }
                }
            }
            .frame(height: maxStackHeight)
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(viewModel.projects) { project in
                    GridEscrowCard(project: project)
                        .onTapGesture {
                            selectedEscrow = mockEscrowDetail(from: project)
                        }
                }
            }
            .padding(16)
            .padding(.top, 20)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("OPEN PROJECTS")
                    .font(.custom("DelaGothicOne-Regular", size: 28))
                    .foregroundColor(.black)
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        viewMode = viewMode == .stack ? .grid : .stack
                    }
                }) {
                    Image(systemName: viewMode == .stack ? "square.grid.2x2" : "square.stack.3d.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                Button(action: { showCreateEscrow = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color("ActiveColor"))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            
            if !viewModel.projects.isEmpty {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(totalCommittedFormatted)
                            .font(.custom("DelaGothicOne-Regular", size: 20))
                            .foregroundColor(.black)
                        
                        Text("TOTAL COMMITTED")
                            .font(.custom("DaysOne-Regular", size: 11))
                            .foregroundColor(.black)
                            .opacity(0.6)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        VStack(spacing: 2) {
                            Text("\(inProgressCount)")
                                .font(.custom("DelaGothicOne-Regular", size: 16))
                                .foregroundColor(.black)
                            
                            Text("ACTIVE")
                                .font(.custom("DaysOne-Regular", size: 9))
                                .foregroundColor(.black)
                                .opacity(0.6)
                        }
                        
                        VStack(spacing: 2) {
                            Text("\(completedCount)")
                                .font(.custom("DelaGothicOne-Regular", size: 16))
                                .foregroundColor(.black)
                            
                            Text("COMPLETE")
                                .font(.custom("DaysOne-Regular", size: 9))
                                .foregroundColor(.black)
                                .opacity(0.6)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .padding(.top, 30)
    }
    
    private var maxStackHeight: CGFloat {
        let lastIndex = max(0, viewModel.projects.count - 1)
        let tallestCard = baseFrontHeight + (CGFloat(lastIndex) * heightIncrement)
        return tallestCard + (CGFloat(lastIndex) * spacing)
    }
    
    private var totalCommittedFormatted: String {
        let total = viewModel.projects.reduce(0) { $0 + $1.totalCommitted }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "$0"
    }
    
    private var inProgressCount: Int {
        viewModel.projects.filter { $0.progress > 0 && $0.progress < 1.0 }.count
    }
    
    private var completedCount: Int {
        viewModel.projects.filter { $0.progress >= 1.0 }.count
    }
    
    private func loadEscrowsIfNeeded() {
        guard !authToken.isEmpty else { return }
        viewModel.loadEscrows(token: authToken)
    }
    
    private func createMilestoneDisplays(for project: EscrowProject) -> [MilestoneDisplay]? {
        guard let milestones = project.milestones, !milestones.isEmpty else {
            return nil
        }
        
        let total = project.totalCommitted
        var cumulativeAmount: Double = 0
        
        return milestones.map { milestone in
            cumulativeAmount += milestone.amount
            let cumulativePercentage = total > 0 ? cumulativeAmount / total : 0
            
            // Create short description
            let shortDesc: String
            if let desc = milestone.description, !desc.isEmpty {
                shortDesc = desc.split(separator: " ").first.map(String.init) ?? String(desc.prefix(10))
            } else {
                shortDesc = "Step"
            }
            
            return MilestoneDisplay(
                id: milestone.id,
                shortDescription: shortDesc,
                cumulativePercentage: min(cumulativePercentage, 1.0),
                isReleased: milestone.released
            )
        }
    }
    
    private func mockEscrowDetail(from project: EscrowProject) -> EscrowDetail {
        // Use actual milestones if available, otherwise create mock ones
        let milestones: [Milestone]
        if let projectMilestones = project.milestones, !projectMilestones.isEmpty {
            milestones = projectMilestones
        } else {
            milestones = [
                Milestone(
                    id: 1,
                    description: "Initial deposit",
                    amount: project.totalCommitted * 0.5,
                    releaseConditions: "Upon contract signing",
                    dueDate: nil,
                    released: false
                ),
                Milestone(
                    id: 2,
                    description: "Midpoint payment",
                    amount: project.totalCommitted * 0.25,
                    releaseConditions: "50% completion",
                    dueDate: nil,
                    released: false
                ),
                Milestone(
                    id: 3,
                    description: "Final payment",
                    amount: project.totalCommitted * 0.25,
                    releaseConditions: "Project delivery",
                    dueDate: nil,
                    released: false
                )
            ]
        }

        return EscrowDetail(
            id: project.id,
            title: project.title,
            subtitle: project.subtitle,
            purpose: "This is a mock escrow purpose for preview/demo.",
            status: "PENDING",
            totalCommitted: project.totalCommitted,
            totalReleased: project.totalCommitted * project.progress,
            progress: project.progress,
            milestones: milestones,
            cancellationPolicy: [
                "You can cancel before production for a partial refund.",
                "You can cancel after production for a smaller refund.",
                "If delivery is missed, you get a full refund."
            ],
            signerImageNames: ["profile1", "profile2"],
            signDate: Date()
        )
    }
}

struct GridEscrowCard: View {
    let project: EscrowProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(project.title)
                .font(.custom("DelaGothicOne-Regular", size: 16))
                .foregroundColor(.black)
                .lineLimit(2)
            
            Text("$\(String(format: "%.0f", project.totalCommitted))")
                .font(.custom("DelaGothicOne-Regular", size: 20))
                .foregroundColor(.black)
            
            HStack {
                Circle()
                    .fill(statusColor(for: project.progress))
                    .frame(width: 8, height: 8)
                
                Text(statusText(for: project.progress))
                    .font(.custom("IBMPlexMono-Regular", size: 11))
                    .foregroundColor(.black.opacity(0.6))
                
                Spacer()
                
                Text("\(Int(project.progress * 100))%")
                    .font(.custom("DaysOne-Regular", size: 12))
                    .foregroundColor(.black.opacity(0.5))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func statusColor(for progress: Double) -> Color {
        switch progress {
        case 0.0: return .orange
        case 0.0..<1.0: return .blue
        case 1.0: return .green
        default: return .gray
        }
    }
    
    private func statusText(for progress: Double) -> String {
        switch progress {
        case 0.0: return "Pending"
        case 0.0..<1.0: return "Active"
        case 1.0: return "Complete"
        default: return "Unknown"
        }
    }
}

struct OpenEscrowsView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = EscrowViewModel()
        vm.projects = [
            EscrowProject(
                id: 1,
                title: "Photography - Hades",
                subtitle: "Service Oct 2",
                progress: 0.5,
                totalCommitted: 10_000,
                milestones: [
                    Milestone(id: 1, description: "Deposit", amount: 5000, releaseConditions: nil, dueDate: nil, released: true),
                    Milestone(id: 2, description: "Final", amount: 5000, releaseConditions: nil, dueDate: nil, released: false)
                ]
            ),
            EscrowProject(
                id: 2,
                title: "Lions vs. Bears",
                subtitle: "GAME FEB 12",
                progress: 0.6,
                totalCommitted: 8_000,
                milestones: nil
            ),
            EscrowProject(
                id: 3,
                title: "For the Love of Sugar",
                subtitle: "DROP JUNE 11",
                progress: 0.3,
                totalCommitted: 5_000,
                milestones: nil
            )
        ]

        return OpenEscrowsView(viewModel: vm)
    }
}
