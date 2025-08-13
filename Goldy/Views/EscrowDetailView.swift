//
//  EscrowDetailView.swift
//  Goldy
//
//  Created by Blair Myers on 4/16/25.
//

import SwiftUI

struct EscrowDetailView: View {
    // Pass this from your card tap: EscrowDetailView(escrowId: project.id)
    let escrowId: Int

    @AppStorage("authToken") private var authToken = ""

    // Live DTO + mapped UI model
    @State private var dto: EscrowDTO?
    @State private var escrow: EscrowDetail?

    @State private var isLoading = false
    @State private var errorText = ""
    @State private var showFundSheet = false

    var body: some View {
        ScrollView {
            if let escrow {
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

                    // Status + Fund button (if pending)
                    HStack {
                        Text(dto?.status.capitalized ?? "")
                            .font(.custom("DaysOne-Regular", size: 12))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.yellow)
                            .cornerRadius(20)

                        Spacer()

                        if dto?.status == "PENDING" {
                            Button("Fund Escrow") { showFundSheet = true }
                                .font(.custom("DaysOne-Regular", size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }

                    // Purpose Section
                    SectionHeader(text: "PURPOSE OF THE ESCROW")
                    InfoCard(text: escrow.purpose ?? "")

                    // Totals (Released)
                    HStack {
                        Text("TOTAL RELEASED AMOUNT")
                            .font(.custom("DaysOne-Regular", size: 14))
                        Spacer()
                        Text(escrow.totalReleased, format: .currency(code: "USD"))
                            .font(.custom("DaysOne-Regular", size: 18))
                            .bold()
                    }

                    // Milestones + vertical progress bar
                    HStack(alignment: .top, spacing: 16) {
                        VStack {
                            Spacer()
                            VerticalMilestoneBar(progress: escrow.progress)
                                .frame(width: 20)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(escrow.milestones) { m in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Milestone \(m.id)")
                                            .font(.custom("DaysOne-Regular", size: 14))
                                        Spacer()
                                        Text(m.amount, format: .currency(code: "USD"))
                                            .font(.custom("DaysOne-Regular", size: 14))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(Color.yellow.opacity(0.8))
                                            .cornerRadius(8)
                                    }

                                    if m.released {
                                        Text("Released")
                                            .font(.custom("DaysOne-Regular", size: 12))
                                            .foregroundColor(.green)
                                    } else if dto?.status == "AUTHORIZED" {
                                        Button("Release") { release(milestoneId: m.id) }
                                            .font(.custom("DaysOne-Regular", size: 12))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    } else {
                                        Text("Locked")
                                            .font(.custom("DaysOne-Regular", size: 12))
                                            .opacity(0.5)
                                    }
                                }
                                .padding()
                                .background(Color("ActiveColor"))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                        }
                    }

                    // Totals (Committed)
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
                    .background(Color("ActiveColor"))
                    .cornerRadius(12)

                    // Signed and Agreed
                    SectionHeader(text: "SIGNED AND AGREED")
                    SignersView(
                        imageNames: escrow.signerImageNames,
                        signDate: escrow.signDate
                    )

                    // View Terms Button
                    Button(action: {
                        // TODO: Show T&C
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
            } else if isLoading {
                ProgressView().padding()
            } else if !errorText.isEmpty {
                Text(errorText).foregroundColor(.red).padding()
            }
        }
        .background(Color("Card1").ignoresSafeArea())
        .onAppear { Task { await reload() } }
        .sheet(isPresented: $showFundSheet, onDismiss: {
            Task { await reload() }    // refresh after funding sheet closes
        }) {
            // Present your existing FundEscrowView
            FundEscrowView(escrowId: escrowId)
        }
    }

    // MARK: - Networking

    private func reload() async {
        guard !authToken.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let all = try await EscrowService.myEscrows(token: authToken)
            if let found = all.first(where: { $0.id == escrowId }) {
                self.dto = found
                self.escrow = found.toDetail() // uses your existing mapper
                self.errorText = ""
            } else {
                self.errorText = "Escrow not found."
            }
        } catch {
            self.errorText = "Failed to load escrow: \(error.localizedDescription)"
        }
    }

    private func release(milestoneId: Int) {
        guard !authToken.isEmpty else { return }
        Task {
            do {
                _ = try await EscrowService.release(
                    escrowId: escrowId,
                    milestoneId: milestoneId,
                    token: authToken
                )
                await reload()
            } catch {
                self.errorText = "Release failed: \(error.localizedDescription)"
            }
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
                Rectangle()
                    .fill(Color("ActiveColor"))

                Rectangle()
                    .fill(Color.black.opacity(0.35))
                    .frame(height: filledHeight)

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
                    .frame(width: 40, height: 40) // fixed from 40x10
                    .clipShape(Circle())
            }
            Text("Executed on \(formattedDate)")
                .font(.custom("DaysOne-Regular", size: 14))
                .foregroundColor(.black)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - Preview

struct EscrowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with a static model (design only)
        let sampleMilestones = [
            Milestone(id: 1, amount: 7250, released: true),
            Milestone(id: 2, amount: 3625, released: false),
            Milestone(id: 3, amount: 3625, released: false)
        ]
        let detail = EscrowDetail(
            id: 1,
            title: "Cabochen Jewelry",
            subtitle: "NEXT MILESTONE ON SEPTEMBER 5, 2025",
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

        VStack(alignment: .leading, spacing: 12) {
            Text("Static Layout (Preview Only)").bold()
            // Render a tiny static snapshot of your old model for design checks
            VStack(alignment: .leading) {
                Text(detail.title)
                Text(detail.subtitle ?? "")
                Text(detail.totalCommitted, format: .currency(code: "USD"))
            }.padding().background(Color("ActiveColor")).cornerRadius(8)

            // Live view (uses escrowId in real app)
            EscrowDetailView(escrowId: 1)
                .previewDisplayName("Live (escrowId)")
        }
        .padding()
        .previewDevice("iPhone 16")
    }
}
