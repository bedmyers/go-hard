//
//  Escrow.swift
//  Goldy
//
//  Created by Blair Myers on 4/11/25.
//

import Foundation
import SwiftUI

struct EscrowProject: Identifiable {
    let id: Int
    let title: String
    let subtitle: String?
    let progress: Double
    let totalCommitted: Double
    let milestones: [Milestone]? // Add this
}

struct EscrowDetail: Identifiable {
    let id: Int
    let title: String
    let subtitle: String?
    let purpose: String?
    let status: String

    let totalCommitted: Double
    let totalReleased: Double
    let progress: Double

    let milestones: [Milestone]

    let cancellationPolicy: [String]
    let signerImageNames: [String]
    let signDate: Date
}

struct ReleaseEvent: Identifiable {
    let id = UUID()
    let description: String
    let amount: Double
    let color: Color
}

struct Milestone: Identifiable, Codable {
    let id: Int
    let description: String?
    let amount: Double
    let releaseConditions: String?
    let dueDate: Date?
    let released: Bool
}
