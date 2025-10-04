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
    let progress: Double
    let totalCommitted: Double
    let cardColorName: String
    let milestones: [MilestoneDisplay]? // Optional array of milestones
    
    // MARK: - Body
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(cardColorName))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear,
                                    Color.black.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            VStack(alignment: .leading) {
                headerSection
                
                progressSection
                
                Spacer()
                
                footerSection
            }
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .padding(.top, 20)
            .padding(.bottom, 47)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        HStack {
            Text(title)
                .font(.custom("DelaGothicOne-Regular", size: 24))
                .foregroundColor(.black)
                .padding(.vertical, 5)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            Text("\(Int(progress * 100))%")
                .font(.custom("DaysOne-Regular", size: 14))
                .foregroundColor(.black)
                .opacity(0.35)
                .padding(.trailing, 10)
        }
        .padding(.top, 0)
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let milestones = milestones, !milestones.isEmpty {
                // Show actual milestone-based progress
                milestoneBar
                milestoneLegend
            } else {
                // Fallback to simple progress bar for escrows without milestones
                simpleProgressBar
                HStack {
                    Text("Started")
                        .font(.custom("DaysOne-Regular", size: 12))
                        .opacity(0.35)
                    Spacer()
                    Text("Complete")
                        .font(.custom("DaysOne-Regular", size: 12))
                        .opacity(0.35)
                }
            }
        }
    }
    
    private var milestoneBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("ActiveColor"))
                    .frame(height: 20)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black)
                    .opacity(0.35)
                    .frame(width: geometry.size.width * progress, height: 20)
                    .animation(.easeInOut(duration: 0.6), value: progress)
                
                // Milestone markers
                if let milestones = milestones {
                    ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                        Rectangle()
                            .fill(Color(cardColorName))
                            .frame(width: 8, height: 20)
                            .position(x: geometry.size.width * milestone.cumulativePercentage, y: 10)
                    }
                }
                
                // Shine effect on progress
                if progress > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 10)
                }
            }
        }
        .frame(height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var simpleProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("ActiveColor"))
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black)
                    .opacity(0.35)
                    .frame(width: geometry.size.width * progress, height: 20)
                    .animation(.easeInOut(duration: 0.6), value: progress)
                
                if progress > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 10)
                }
            }
        }
        .frame(height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var milestoneLegend: some View {
        HStack(alignment: .top, spacing: 0) {
            if let milestones = milestones {
                ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                    VStack(alignment: index == 0 ? .leading : (index == milestones.count - 1 ? .trailing : .center), spacing: 2) {
                        Text(milestone.shortDescription)
                            .font(.custom("DaysOne-Regular", size: 10))
                            .opacity(milestone.isReleased ? 0.5 : 0.35)
                            .lineLimit(2)
                            .multilineTextAlignment(index == 0 ? .leading : (index == milestones.count - 1 ? .trailing : .center))
                        
                        if milestone.isReleased {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.black.opacity(0.4))
                        }
                    }
                    .frame(maxWidth: index == 0 || index == milestones.count - 1 ? .infinity : nil, alignment: index == 0 ? .leading : (index == milestones.count - 1 ? .trailing : .center))
                    
                    if index < milestones.count - 1 {
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TOTAL COMMITTED AMOUNT")
                    .font(.custom("DaysOne-Regular", size: 13))
                    .opacity(0.35)
                
                Spacer()
                
                statusBadge
            }
            
            Text("$\(String(format: "%.2f", totalCommitted))")
                .font(.custom("DaysOne-Regular", size: 20))
                .bold()
                .foregroundColor(.black)
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText.uppercased())
                .font(.custom("DaysOne-Regular", size: 10))
                .foregroundColor(.black)
                .opacity(0.6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.3))
        )
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch progress {
        case 0.0:
            return Color.orange
        case 0.0..<1.0:
            return Color.blue
        case 1.0:
            return Color.green
        default:
            return Color.gray
        }
    }
    
    private var statusText: String {
        switch progress {
        case 0.0:
            return "Pending"
        case 0.0..<1.0:
            return "Active"
        case 1.0:
            return "Complete"
        default:
            return "Unknown"
        }
    }
}

// MARK: - Supporting Types

struct MilestoneDisplay: Identifiable {
    let id: Int
    let shortDescription: String
    let cumulativePercentage: Double // Position on the bar (0.0 to 1.0)
    let isReleased: Bool
}

// MARK: - Preview

struct EscrowCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Example with custom milestones
            EscrowCardView(
                title: "Cabochon Jewelry",
                subtitle: "NEXT MILESTONE ON SEPTEMBER 5, 2025",
                progress: 0.5,
                totalCommitted: 14500.00,
                cardColorName: "Card1",
                milestones: [
                    MilestoneDisplay(id: 1, shortDescription: "Deposit", cumulativePercentage: 0.5, isReleased: true),
                    MilestoneDisplay(id: 2, shortDescription: "Design\nApproval", cumulativePercentage: 0.75, isReleased: false),
                    MilestoneDisplay(id: 3, shortDescription: "Final\nDelivery", cumulativePercentage: 1.0, isReleased: false)
                ]
            )
            .frame(height: 300)
            
            // Example with no milestones (simple progress)
            EscrowCardView(
                title: "Vintage Watch",
                subtitle: "DELIVERY EXPECTED OCTOBER 2025",
                progress: 0.25,
                totalCommitted: 25000.00,
                cardColorName: "Card2",
                milestones: nil
            )
            .frame(height: 300)
        }
        .padding()
        .background(Color(red: 0.97, green: 0.93, blue: 0.85))
    }
}
