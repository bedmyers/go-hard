//
//  OpenEscrowsView.swift
//  Goldy
//
//  Created by Blair Myers on 3/5/25.
//

import SwiftUI

struct OpenEscrowsView: View {
    let projects: [EscrowProject]
    
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
                ForEach(projects.indices, id: \.self) { i in
                    let project = projects[i]
                    
                    // Calculate each card’s height:
                    //   i=0 => 300
                    //   i=1 => 350
                    //   i=2 => 400, etc.
                    let heightAdded = i <= 3 ? heightIncrement : heightIncrementAfter4
                    let heightForThisCard = baseFrontHeight + (CGFloat(i) * heightAdded)
                    
                    let cardColorIndex = (i % 7) + 1    // yields 1..7
                    let cardColorName = "Card\(cardColorIndex)"

                    EscrowCardView(
                        title: project.title,
                        subtitle: project.subtitle,
                        progress: project.progress,
                        totalCommitted: project.totalCommitted,
                        cardColorName: cardColorName
                    )
                    .frame(height: heightForThisCard)
                    
                    // Negative offset to place subsequent cards “above” the bottom card
                    .offset(y: -CGFloat(i) * spacing)
                    
                    // Ensure card 0 (the bottom card) has highest z‐index
                    .zIndex(Double(projects.count - i))
                }
            }
            // Figure out how tall the tallest card might be
            //   For i = (projects.count - 1), the card is baseFrontHeight + (lastIndex * 50)
            // Then add enough vertical space for (count - 1) offsets
            .frame(height: maxStackHeight)
            .padding(.top, 100)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        // Background gradient
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
        let lastIndex = max(0, projects.count - 1)
        let tallestCard = baseFrontHeight + (CGFloat(lastIndex) * heightIncrement)
        
        // Then we offset each subsequent card by spacing,
        // so total needed: tallestCard + (lastIndex * spacing).
        return tallestCard + (CGFloat(lastIndex) * spacing)
    }
}


// MARK: - Example Preview
#Preview {
    OpenEscrowsView(projects: [
        EscrowProject(
            title: "2021 FORD F150",
            subtitle: "FINAL DELIVERY ON JANUARY 28, 2025",
            progress: 0.85,
            totalCommitted: 10_000
        ),
        EscrowProject(
            title: "Lions vs. Bears",
            subtitle: "FINAL DELIVERY ON JANUARY 28, 2025",
            progress: 0.85,
            totalCommitted: 8_000
        ),
        EscrowProject(
            title: "For the Love of Sugar",
            subtitle: "GOING HARD ON JUNE 11, 2025",
            progress: 0.60,
            totalCommitted: 5_000
        ),
        EscrowProject(
            title: "Caboch en Jewelry",
            subtitle: "NEXT MILESTONE ON SEPTEMBER 5, 2025",
            progress: 0.75,
            totalCommitted: 14_500
        ),
        // Fifth item to test the smaller incremental peek
        EscrowProject(
            title: "Extra Project #5",
            subtitle: "SMALL PEEK BEHIND THE 4TH CARD",
            progress: 0.40,
            totalCommitted: 2_000
        )
    ])
}
