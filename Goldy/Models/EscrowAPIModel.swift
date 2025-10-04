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
    let description: String?
    let amountCents: Int
    let releaseConditions: String?
    let dueDate: String?
    let released: Bool
}

extension EscrowDTO {
    func toProject() -> EscrowProject {
        let total = Double(amountCents) / 100.0
        let released = milestones.filter { $0.released }
            .map { Double($0.amountCents) / 100.0 }
            .reduce(0, +)
        let progress = total > 0 ? (released / total) : 0
        
        // Convert milestones
        let convertedMilestones = milestones.map { $0.toMilestone() }

        return EscrowProject(
            id: id,
            title: title ?? "Untitled Escrow",
            subtitle: nil,
            progress: progress,
            totalCommitted: total,
            milestones: convertedMilestones  // Add this
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
        let date: Date?
        if let dueDateString = dueDate {
            date = ISO8601DateFormatter().date(from: dueDateString)
        } else {
            date = nil
        }
            
        return Milestone(
            id: id,
            description: description,
            amount: Double(amountCents) / 100.0,
            releaseConditions: releaseConditions,
            dueDate: date,
            released: released
        )
    }
}
