//
//  OpenEscrowsView.swift
//  Goldy
//
//  Created by Blair Myers on 3/5/25.
//

import SwiftUI

struct OpenEscrowsView: View {
    @ObservedObject var viewModel: EscrowViewModel
    @State private var selectedEscrow: EscrowDetail? = nil
    @State private var showCreateEscrow = false
    @AppStorage("authToken") private var authToken: String = ""

    /// The front (bottom) card's base height
    private let baseFrontHeight: CGFloat = 300
    
    /// Each subsequent card behind is taller than the one in front
    private let heightIncrement: CGFloat = 32
    private let heightIncrementAfter4: CGFloat = 12
    
    /// Vertical spacing between each stacked card
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
    
    // MARK: - View Components
    
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
        VStack(alignment: .leading) {
            // Header with your signature styling
            headerSection
            
            Spacer()
            
            // Your distinctive stacked cards layout
            ZStack(alignment: .bottom) {
                ForEach(viewModel.projects.indices, id: \.self) { i in
                    let project = viewModel.projects[i]
                    let heightAdded = i <= 3 ? heightIncrement : heightIncrementAfter4
                    let heightForThisCard = baseFrontHeight + (CGFloat(i) * heightAdded)
                    let cardColorIndex = (i % 7) + 1
                    let cardColorName = "Card\(cardColorIndex)"
                    
                    EscrowCardView(
                        title: project.title,
                        subtitle: project.subtitle ?? "",
                        progress: project.progress,
                        totalCommitted: project.totalCommitted,
                        cardColorName: cardColorName
                    )
                    .frame(height: heightForThisCard)
                    .offset(y: -CGFloat(i) * spacing)
                    .zIndex(Double(viewModel.projects.count - i))
                    .onTapGesture {
                        selectedEscrow = mockEscrowDetail(from: project)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateEscrow = true }) {
                        Image(systemName: "plus")
                            .imageScale(.large)
                            .foregroundColor(.black)
                    }
                }
            }
            .frame(height: maxStackHeight)
            .padding(.top, 100)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(
            // Your signature warm gradient
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
            CreateEscrowView(viewModel: viewModel, onComplete: {
                viewModel.loadEscrows(token: authToken)
                showCreateEscrow = false
            })
        }
        .sheet(item: $selectedEscrow) { escrow in
            EscrowDetailView(escrowId: escrow.id)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("OPEN PROJECTS")
                    .font(.custom("DelaGothicOne-Regular", size: 28))
                    .foregroundColor(.black)
                Spacer()
                
                // Branded create button
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
            
            // Summary stats with your brand styling
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
    
    // MARK: - Computed Properties
    
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
    
    // MARK: - Helper Methods
    
    private func loadEscrowsIfNeeded() {
        guard !authToken.isEmpty else { return }
        viewModel.loadEscrows(token: authToken)
    }
    
    private func mockEscrowDetail(from project: EscrowProject) -> EscrowDetail {
        let mockMilestones: [Milestone] = [
            Milestone(id: 1, amount: project.totalCommitted * 0.5, released: false),
            Milestone(id: 2, amount: project.totalCommitted * 0.25, released: false),
            Milestone(id: 3, amount: project.totalCommitted * 0.25, released: false)
        ]

        return EscrowDetail(
            id: project.id,
            title: project.title,
            subtitle: project.subtitle,
            purpose: "This is a mock escrow purpose for preview/demo.",
            status: "PENDING",
            totalCommitted: project.totalCommitted,
            totalReleased: project.totalCommitted * project.progress,
            progress: project.progress,
            milestones: mockMilestones,
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

// MARK: - Preview

struct OpenEscrowsView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = EscrowViewModel()
        vm.projects = [
            EscrowProject(id: 1, title: "2021 FORD F150", subtitle: "DELIVERY JAN 28", progress: 0.85, totalCommitted: 10_000),
            EscrowProject(id: 2, title: "Lions vs. Bears", subtitle: "GAME FEB 12", progress: 0.6, totalCommitted: 8_000),
            EscrowProject(id: 3, title: "For the Love of Sugar", subtitle: "DROP JUNE 11", progress: 0.3, totalCommitted: 5_000)
        ]

        return OpenEscrowsView(viewModel: vm)
    }
}
