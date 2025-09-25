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
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Card background with more distinctive styling
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(cardColorName))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                .overlay(
                    // Subtle texture overlay
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
                // Header section
                headerSection
                
                // Progress section with more character
                progressSection
                
                Spacer()
                
                // Footer section
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
            
            // More distinctive progress indicator
            Text("\(Int(progress * 100))%")
                .font(.custom("DaysOne-Regular", size: 14))
                .foregroundColor(.black)
                .opacity(0.35)
                .padding(.trailing, 10)
        }
        .padding(.top, 0)
    }
    
    private var subtitleSection: some View {
        Text(subtitle)
            .font(.custom("DaysOne-Regular", size: 15))
            .opacity(0.35)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.top, -12)
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Distinctive milestone bar
            milestoneBar
            
            // Original milestone labels with character
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
            .opacity(0.35)
        }
    }
    
    private var milestoneBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background with your original styling
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("ActiveColor"))
                    .frame(height: 20)
                
                // Progress fill with more character
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black)
                    .opacity(0.35)
                    .frame(width: geometry.size.width * progress, height: 20)
                    .animation(.easeInOut(duration: 0.6), value: progress)
                
                // Distinctive milestone dividers
                ForEach([0.25, 0.5, 0.75], id: \.self) { milestone in
                    Rectangle()
                        .fill(Color(cardColorName))
                        .frame(width: 8, height: 20)
                        .position(x: geometry.size.width * milestone, y: 10)
                }
                
                // Add some visual interest with subtle highlights
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
    
    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TOTAL COMMITTED AMOUNT")
                    .font(.custom("DaysOne-Regular", size: 13))
                    .opacity(0.35)
                
                Spacer()
                
                // Status with more character
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

// MARK: - Preview

struct EscrowCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            EscrowCardView(
                title: "Cabochon Jewelry",
                subtitle: "NEXT MILESTONE ON SEPTEMBER 5, 2025",
                progress: 0.75,
                totalCommitted: 14500.00,
                cardColorName: "Card1"
            )
            .frame(height: 300)
            
            EscrowCardView(
                title: "Vintage Watch Collection",
                subtitle: "DELIVERY EXPECTED OCTOBER 2025",
                progress: 0.25,
                totalCommitted: 25000.00,
                cardColorName: "Card2"
            )
            .frame(height: 300)
        }
        .padding()
        .background(Color(red: 0.97, green: 0.93, blue: 0.85))
    }
}
