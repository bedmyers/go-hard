//
//  EscrowAPIModel.swift
//  Goldy
//
//  Created by Blair Myers on 8/11/25.
//

import Foundation

struct EscrowDTO: Decodable {
    let id: Int
    let title: String?
    let buyerId: Int
    let sellerId: Int
    let amountCents: Int
    let status: String
    let stripePaymentIntentId: String?
    let milestones: [MilestoneDTO]
}

struct MilestoneDTO: Decodable {
    let id: Int
    let escrowId: Int
    let amountCents: Int
    let released: Bool
}

extension EscrowDTO {
    func toProject() -> EscrowProject {
        let total = Double(amountCents) / 100.0
        // progress = released / total (fallback 0 if no milestones yet)
        let released = milestones.filter { $0.released }
            .map { Double($0.amountCents) / 100.0 }
            .reduce(0, +)
        let progress = total > 0 ? (released / total) : 0

        return EscrowProject(
            id: id,
            title: title ?? "Untitled Escrow",
            subtitle: nil, // fill later if you want
            progress: progress,
            totalCommitted: total
        )
    }

    func toDetail() -> EscrowDetail {
        let total = Double(amountCents) / 100.0
        let released = milestones.filter { $0.released }
            .map { Double($0.amountCents) / 100.0 }
            .reduce(0, +)
        let progress = total > 0 ? (released / total) : 0

        return EscrowDetail(
            id: id,
            title: title ?? "Untitled Escrow",
            subtitle: nil,
            purpose: nil,
            status: status,
            totalCommitted: total,
            totalReleased: released,
            progress: progress,
            milestones: milestones.map { $0.toMilestone() },
            cancellationPolicy: [],
            signerImageNames: [],
            signDate: Date()
        )
    }
}

extension MilestoneDTO {
    func toMilestone() -> Milestone {
        Milestone(
            id: id,
            amount: Double(amountCents) / 100.0,
            released: released
        )
    }
}
