//
//  EscrowCardView.swift
//  Goldy
//
//  Created by Blair Myers on 3/5/25.
//

import SwiftUI

struct EscrowCardView: View {
    // MARK: - Input Properties
    let title: String
    let subtitle: String
    /// Progress between 0.0 and 1.0, e.g. 0.75 for 75%.
    let progress: Double
    let totalCommitted: Double
    let cardColorName: String
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Card background with corner radius
            RoundedRectangle(cornerRadius: 20)
                // Replace "CardBackground" with your custom color asset or a default Color
                .fill(Color(cardColorName))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading) {
                // Top row: Title + Progress
                HStack {
                    Text(title)
                        .font(.custom("DelaGothicOne-Regular", size: 24))
                        .foregroundColor(.black)
                        .padding(.vertical, 5)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    // Display integer percentage (e.g., 75%)
                    Text("\(Int(progress * 100))%")
                        .font(.custom("DaysOne-Regular", size: 14))
                        .foregroundColor(.black)
                        .opacity(35.0 / 100.0)
                        .padding(.trailing, 10)
                }
                .padding(.top, 0)
                
                // Subtitle
                Text(subtitle)
                    .font(.custom("DaysOne-Regular", size: 15))
                    .opacity(35.0 / 100.0)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, -12)
                
                Spacer()
                
                // Milestone progress bar
                milestoneBar
                
                // Milestone labels
                HStack {
                    Text("Escrow\nexecuted")
                    Spacer()
                    Text("50%\nrelease")
                    Spacer()
                    Text("75%\nrelease")
                    Spacer()
                    Text("100%\nrelease")
                    Spacer()
                }
                .font(.custom("DaysOne-Regular", size: 12))
                .opacity(35.0 / 100.0)
                
                Spacer()
                // Footer row
                HStack {
                    Text("TOTAL COMMITTED AMOUNT")
                        .font(.custom("DaysOne-Regular", size: 13))
                        .opacity(35.0 / 100.0)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", totalCommitted))")
                        .font(.custom("DaysOne-Regular", size: 20))
                        .bold()
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .padding(.top, 20)
            .padding(.bottom, 47)
        }
        // Adjust the overall card size as needed
        //.frame(height: 300)
    }
    
    // MARK: - Milestone Bar
    private var milestoneBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 1) Background (unfilled)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("ActiveColor"))
                    .frame(height: 20)
                
                // 2) Foreground (filled portion)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.black))
                    .opacity(35.0 / 100.0)
                    // Multiply total width by your `progress` (0...1)
                    .frame(width: geometry.size.width * progress,
                           height: 20)
                
                // 3) Optional vertical dividers to show “segments”
                //    (0.25, 0.5, 0.75, etc.)
                ForEach([0.25, 0.5, 0.75], id: \.self) { milestone in
                    Rectangle()
                        // Adjust color/opacity to suit your design
                        .fill(Color(cardColorName))
                        .frame(width: 8, height: 20)
                        // Position each divider at the correct fraction
                        .position(x: geometry.size.width * milestone,
                                  y: 10) // half of bar height
                }
            }
        }
        // Ensure the GeometryReader has a fixed height
        .frame(height: 20)
        // Clip the entire shape if you like
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }


    
    /// Determines the color for each segment based on `progress`.
    /// Each segment represents 25% (i.e., 1/4) of the total progress.
    private func segmentColor(for index: Int) -> Color {
        // 4 segments => each covers 0.25 progress
        let segmentThreshold = Double(index + 1) * 0.25
        
        // If our overall progress is beyond this segment's threshold, it's "active".
        // Otherwise, it's "inactive".
        return progress >= segmentThreshold
            ? Color("ActiveSegment")    // Replace with your "filled" color
            : Color("InactiveSegment")  // Replace with your "unfilled" color
    }
}

// MARK: - Preview
struct EscrowCardView_Previews: PreviewProvider {
    static var previews: some View {
        EscrowCardView(
            title: "Cabochen Jewelry",
            subtitle: "NEXT MILESTONE ON SEPTEMBER 5, 2025",
            progress: 0.75,
            totalCommitted: 14500.00,
            cardColorName: "Card1"
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
