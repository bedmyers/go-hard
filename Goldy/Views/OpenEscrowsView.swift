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
    @State private var showDetail: Bool = false
    @State private var showCreateEscrow = false
    @AppStorage("authToken") private var authToken: String = ""

    
    /// The front (bottom) card’s base height
    private let baseFrontHeight: CGFloat = 300
    
    /// Each subsequent card behind is 50 pts taller than the one in front
    private let heightIncrement: CGFloat = 32
    private let heightIncrementAfter4: CGFloat = 12
    
    /// Vertical spacing between each stacked card
    private let spacing: CGFloat = 70
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // MARK: - Header
            HStack {
                Text("OPEN PROJECTS")
                    .font(.custom("DelaGothicOne-Regular", size: 28))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.title2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .padding(.top, 30)
            
            Spacer()
            
            // MARK: - Overlapping ZStack
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
                        // Convert project → EscrowDetail for now with mock data
                        selectedEscrow = mockEscrowDetail(from: project)
                        showDetail = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateEscrow = true
                    }) {
                        Image(systemName: "plus")
                            .imageScale(.large)
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $showCreateEscrow) {
                CreateEscrowView(viewModel: viewModel)
            }
            .sheet(item: $selectedEscrow) { escrow in
                EscrowDetailView(escrow: escrow)
            }
            // Figure out how tall the tallest card might be
            //   For i = (projects.count - 1), the card is baseFrontHeight + (lastIndex * 50)
            // Then add enough vertical space for (count - 1) offsets
            .frame(height: maxStackHeight)
            .padding(.top, 100)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .onAppear {
            viewModel.loadEscrows(token: authToken)
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
    }
    
    /// Computes the total ZStack height needed so the largest (rearmost) card is fully in view:
    private var maxStackHeight: CGFloat {
        // If there are `n` projects, the last index = (n-1).
        // The tallest card = baseFrontHeight + (lastIndex * heightIncrement).
        let lastIndex = max(0, viewModel.projects.count - 1)
        let tallestCard = baseFrontHeight + (CGFloat(lastIndex) * heightIncrement)
        
        // Then we offset each subsequent card by spacing,
        // so total needed: tallestCard + (lastIndex * spacing).
        return tallestCard + (CGFloat(lastIndex) * spacing)
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


// MARK: - Example Preview
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
