//
//  EscrowDetailView.swift
//  Goldy
//
//  Created by Blair Myers on 4/16/25.
//

import SwiftUI

struct EscrowDetailView: View {
    let escrow: EscrowDetail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text(escrow.title)
                        .font(.custom("DelaGothicOne-Regular", size: 28))
                        .foregroundColor(.black)
                    Text(escrow.subtitle ?? "")
                        .font(.custom("DaysOne-Regular", size: 16))
                        .opacity(0.35)
                }

                // Purpose Section
                SectionHeader(text: "PURPOSE OF THE ESCROW")
                InfoCard(text: escrow.purpose ?? "")
                
                HStack {
                    Text("TOTAL RELEASED AMOUNT")
                        .font(.custom("DaysOne-Regular", size: 14))
                    Spacer()
                    Text(escrow.totalReleased, format: .currency(code: "USD"))
                        .font(.custom("DaysOne-Regular", size: 18))
                        .bold()
                }
                
                HStack(alignment: .top, spacing: 16) {
                    VStack {
                        Spacer()
                        VerticalMilestoneBar(progress: escrow.progress)
                            .frame(width: 20)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(makeReleaseEvents(from: escrow.milestones)) { event in
                            MilestoneCard(event: event)
                        }
                    }
                }
                
                HStack {
                    Text("TOTAL COMMITTED AMOUNT")
                        .font(.custom("DaysOne-Regular", size: 14))
                    Spacer()
                    Text(escrow.totalCommitted, format: .currency(code: "USD"))
                        .font(.custom("DaysOne-Regular", size: 18))
                        .bold()
                }

                // Cancellation & Refund Policy
                SectionHeader(text: "CANCELLATION & REFUND POLICY")
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(escrow.cancellationPolicy, id: \.self) { item in
                        CancellationItem(text: item)
                    }
                }
                .padding()
                .background(Color("ActiveColor")) // or use Color.white if not themed
                .cornerRadius(12)

                // Signed and Agreed
                SectionHeader(text: "SIGNED AND AGREED")
                SignersView(
                    imageNames: escrow.signerImageNames,
                    signDate: escrow.signDate
                )

                // View Terms Button
                Button(action: {
                    // Show T&C
                }) {
                    Text("VIEW TERMS AND CONDITIONS")
                        .font(.custom("DaysOne-Regular", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(24)
                }
            }
            .padding(16)
        }
        .background(Color("Card1").ignoresSafeArea())
    }
    
    func makeReleaseEvents(from milestones: [Milestone]) -> [ReleaseEvent] {
        let colors: [Color] = [.orange.opacity(0.8), .yellow.opacity(0.8), .gray.opacity(0.6)]
        return milestones.enumerated().map { index, milestone in
            ReleaseEvent(
                description: "Milestone \(index + 1)",
                amount: milestone.amount,
                color: colors[index % colors.count]
            )
        }
    }
}

// MARK: - Segmented Vertical Bar

struct VerticalMilestoneBar: View {
    let progress: Double  // 0.0...1.0

    var body: some View {
        GeometryReader { geometry in
            let stepCount = 4
            let totalHeight = geometry.size.height
            let stepHeight = totalHeight / CGFloat(stepCount)
            let filledHeight = totalHeight * CGFloat(progress)

            ZStack(alignment: .bottom) {
                // Base track (no corner radius)
                Rectangle()
                    .fill(Color("ActiveColor"))

                // Filled portion (no corner radius)
                Rectangle()
                    .fill(Color.black.opacity(0.35))
                    .frame(height: filledHeight)

                // Dividers
                ForEach(1..<stepCount, id: \.self) { index in
                    Rectangle()
                        .fill(Color("Card1"))
                        .frame(width: 20, height: 4)
                        .position(
                            x: geometry.size.width / 2,
                            y: stepHeight * CGFloat(index)
                        )
                }
            }
        }
    }
}

// MARK: - Milestone Card

struct MilestoneCard: View {
    let event: ReleaseEvent

    var body: some View {
        VStack(alignment: .leading) {
            // Description at the top
            Text(event.description)
                .font(.custom("DaysOne-Regular", size: 14))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Amount badge bottom-right
            HStack {
                Spacer()
                Text(event.amount, format: .currency(code: "USD"))
                    .font(.custom("DaysOne-Regular", size: 14))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(event.color)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color("ActiveColor"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Reusable Subviews

private struct SectionHeader: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.custom("DelaGothicOne-Regular", size: 16))
            .foregroundColor(.black)
    }
}

private struct InfoCard: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.custom("DaysOne-Regular", size: 14))
            .foregroundColor(.black)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("ActiveColor"))
            .cornerRadius(8)
            .shadow(radius: 1)
    }
}

private struct CancellationItem: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.black)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.custom("DaysOne-Regular", size: 14))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SignersView: View {
    let imageNames: [String]
    let signDate: Date
    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: signDate)
    }
    var body: some View {
        VStack(spacing: 8) {
            ForEach(imageNames, id: \.self) { name in
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 10)
                    .clipShape(Circle())
            }
            Text("Executed on \(formattedDate)")
                .font(.custom("DaysOne-Regular", size: 14))
                .foregroundColor(.black)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - Previews

struct EscrowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEvents = [
            ReleaseEvent(
                description: "The Depositor shall deposit $14,500 into escrow upon signing this Agreement.",
                amount: 14500,
                color: Color.orange.opacity(0.8)
            ),
            ReleaseEvent(
                description: "50% Release upon completion of a CAD design approval by the Buyer.",
                amount: 7250,
                color: Color.yellow.opacity(0.8)
            ),
            ReleaseEvent(
                description: "25% Release upon completion of the ring casting and setting, with photographs provided to the Buyer.",
                amount: 3625,
                color: Color.gray.opacity(0.6)
            )
        ]
        let sampleMilestones = [
            Milestone(id: 1, amount: 7250, released: true),
            Milestone(id: 2, amount: 3625, released: false),
            Milestone(id: 3, amount: 3625, released: false)
        ]
        let detail = EscrowDetail(
            id: 1,
            title: "Cabochen Jewelry",
            subtitle: "NEXT MILESTONE ON SEPTEMBER 5, 2025",
            purpose: "The Buyer is commissioning a custom engagement ring from the Jeweler.",
            status: "PENDING",
            totalCommitted: 14500,
            totalReleased: 5000,
            progress: 0.8,
            milestones: sampleMilestones,
            cancellationPolicy: [
                "If the Buyer cancels before production begins, the escrow funds (minus a non‑refundable deposit of $500) will be returned.",
                "If the Buyer cancels after production begins, the Jeweler may retain a portion of the funds to cover material and labor costs.",
                "If the Jeweler fails to complete the ring within 8 weeks without reasonable cause, the Buyer gets a full refund."
            ],
            signerImageNames: ["profile1", "profile2"],
            signDate: Date()
        )
        EscrowDetailView(escrow: detail)
            .previewDevice("iPhone 16")
    }
}
