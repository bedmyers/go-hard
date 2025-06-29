//
//  Escrow.swift
//  Goldy
//
//  Created by Blair Myers on 4/11/25.
//

import Foundation
import SwiftUI

struct EscrowProject: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let progress: Double
    let totalCommitted: Double
}

struct EscrowDetail: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let purpose: String
    
    /// **NEW**: overall percent complete (0.0–1.0)
    let progress: Double
    
    let totalReleased: Double
    let releaseEvents: [ReleaseEvent]
    let totalCommitted: Double
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
