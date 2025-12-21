//
//  Project.swift
//  Goldy
//
//  Created by Blair Myers on 11/17/25.
//

import Foundation
import SwiftUI

// MARK: - Project
struct Project: Identifiable, Codable {
    let id: Int
    let title: String
    let description: String?
    let totalBudget: Int? // in cents
    let eventDate: Date?
    let location: String?
    let pinterestBoard: String?
    let status: ProjectStatus
    let customerId: Int
    let customer: User
    let vendors: [ProjectVendor]
    let createdAt: Date
    let updatedAt: Date

    // For vendor projects - contains the vendor's own role info
    let myVendorRole: MyVendorRole?
    
    // Computed properties for UI
    var progressPercentage: Int {
        guard !vendors.isEmpty else { return 0 }
        let completedVendors = vendors.filter { $0.status == "COMPLETED" || $0.status == "PAID" }.count
        return Int((Double(completedVendors) / Double(vendors.count)) * 100)
    }
    
    var totalAmountInEscrow: Double {
        Double(vendors.reduce(0) { $0 + ($1.escrow?.amountCents ?? 0) }) / 100.0
    }
    
    var totalBudgetDollars: Double? {
        guard let budget = totalBudget else { return nil }
        return Double(budget) / 100.0
    }
    
    var statusColor: Color {
        switch status {
        case .planning: return Color(hex: "E9D5FF")
        case .active: return Color(hex: "BBF7D0")
        case .completed: return Color(hex: "FED7AA")
        case .canceled: return .gray
        }
    }
    
    var nextMilestone: String {
        if let eventDate = eventDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Event \(formatter.localizedString(for: eventDate, relativeTo: Date()))"
        }
        
        // Check for upcoming milestone
        let upcomingMilestones = vendors.compactMap { $0.escrow?.milestones }
            .flatMap { $0 }
            .filter { !$0.released }
            .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        
        if let next = upcomingMilestones.first, let dueDate = next.dueDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Milestone due \(formatter.localizedString(for: dueDate, relativeTo: Date()))"
        }
        
        return "No upcoming milestones"
    }
    
    var imageURL: URL? {
        // Could fetch from Pinterest board or vendor portfolios
        nil
    }
}

// MARK: - Project Status
enum ProjectStatus: String, Codable {
    case planning = "PLANNING"
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case canceled = "CANCELED"
}

// MARK: - Project Vendor
struct ProjectVendor: Codable, Identifiable {
    let id: Int
    let projectId: Int
    let vendorId: Int
    let vendor: User
    let role: String
    let description: String?
    let amountCents: Int
    let dueDate: Date?
    let status: String
    let escrow: Escrow?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Escrow
struct Escrow: Codable, Identifiable {
    let id: Int
    let projectVendorId: Int
    let buyerId: Int
    let sellerId: Int
    let amountCents: Int
    let status: String
    let stripePaymentIntentId: String?
    let milestones: [Milestone]
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Milestone
struct Milestone: Codable, Identifiable {
    let id: Int
    let escrowId: Int
    let description: String?
    let amountCents: Int
    let releaseConditions: String?
    let dueDate: Date?
    let released: Bool
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - My Vendor Role (for vendor's view of projects they're part of)
struct MyVendorRole: Codable {
    let id: Int  // This is the projectVendorId
    let role: String
    let amountCents: Int
    let status: String
    let escrow: Escrow?

    var isPending: Bool {
        status == "INVITED" || status == "PENDING"
    }

    var isAccepted: Bool {
        status == "ACCEPTED"
    }

    var amountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Double(amountCents) / 100.0)) ?? "$0"
    }
}
