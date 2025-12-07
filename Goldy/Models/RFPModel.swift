//
//  RFPModel.swift
//  Goldy
//
//  Created by Blair Myers on 11/28/25.
//

import Foundation

// MARK: - RFP (Request for Proposal)

struct RFP: Codable, Identifiable {
    let id: Int
    let projectId: Int?
    let customerId: Int
    let title: String
    let description: String
    let budget: Int?
    let deadline: Date?
    let status: RFPStatus
    
    // Event details
    let eventDate: Date?
    let location: String?
    let guestCount: Int?
    
    // Style & inspiration
    let inspirationUrl: String?
    let styleTags: [String]?
    
    // Requirements
    let mustHaves: [String]?
    let niceToHaves: [String]?
    
    // Timeline
    let decisionDate: Date?
    
    // Visibility
    let visibility: RFPVisibility?
    let invitedVendorIds: [Int]?
    
    // Relations
    let bids: [Bid]?
    let customer: RFPUser?
    let project: RFPProject?
    let createdAt: Date
    let updatedAt: Date
    
    enum RFPStatus: String, Codable {
        case open = "OPEN"
        case awarded = "AWARDED"
        case closed = "CLOSED"
    }
    
    enum RFPVisibility: String, Codable {
        case `public` = "PUBLIC"
        case `private` = "PRIVATE"
    }
    
    var budgetFormatted: String {
        guard let budget = budget else { return "Flexible" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Double(budget) / 100.0)) ?? "$0"
    }
    
    var bidCount: Int {
        bids?.count ?? 0
    }
    
    var isOpen: Bool {
        status == .open
    }
    
    var isPublic: Bool {
        visibility == .public || visibility == nil
    }
    
    var guestCountFormatted: String {
        guard let count = guestCount else { return "TBD" }
        return "\(count) guests"
    }
}

// MARK: - Simplified nested types (API returns minimal objects)

struct RFPUser: Codable {
    let id: Int
    let name: String
    let email: String?
}

struct RFPProject: Codable {
    let id: Int
    let title: String
}

// MARK: - Bid (Vendor Proposal)

struct Bid: Codable, Identifiable {
    let id: Int
    let rfpId: Int
    let vendorId: Int
    let vendor: RFPVendor?
    let rfp: BidRFP?
    let amount: Int
    let proposal: String
    let status: BidStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum BidStatus: String, Codable {
        case submitted = "SUBMITTED"
        case accepted = "ACCEPTED"
        case rejected = "REJECTED"
    }
    
    var amountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Double(amount) / 100.0)) ?? "$0"
    }
    
    var isSubmitted: Bool {
        status == .submitted
    }
}

struct BidRFP: Codable {
    let id: Int
    let title: String
    let description: String?
    let budget: Int?
    let status: String?
}

struct RFPVendor: Codable {
    let id: Int
    let name: String
    let email: String
    let bio: String?
    let services: [String]?
    let portfolioUrls: [String]?
    let location: String?
}

// MARK: - Style Tags

enum StyleTag: String, CaseIterable {
    case naturalLight = "natural-light"
    case gardenParty = "garden-party"
    case rustic = "rustic"
    case modern = "modern"
    case elegant = "elegant"
    case bohemian = "bohemian"
    case vintage = "vintage"
    case minimalist = "minimalist"
    case glamorous = "glamorous"
    case tropical = "tropical"
    case romantic = "romantic"
    case industrial = "industrial"
    
    var displayName: String {
        switch self {
        case .naturalLight: return "Natural Light"
        case .gardenParty: return "Garden Party"
        case .rustic: return "Rustic"
        case .modern: return "Modern"
        case .elegant: return "Elegant"
        case .bohemian: return "Bohemian"
        case .vintage: return "Vintage"
        case .minimalist: return "Minimalist"
        case .glamorous: return "Glamorous"
        case .tropical: return "Tropical"
        case .romantic: return "Romantic"
        case .industrial: return "Industrial"
        }
    }
    
    var icon: String {
        switch self {
        case .naturalLight: return "sun.max.fill"
        case .gardenParty: return "leaf.fill"
        case .rustic: return "house.fill"
        case .modern: return "building.2.fill"
        case .elegant: return "sparkles"
        case .bohemian: return "wind"
        case .vintage: return "clock.fill"
        case .minimalist: return "square"
        case .glamorous: return "star.fill"
        case .tropical: return "palm.tree.fill"
        case .romantic: return "heart.fill"
        case .industrial: return "gear"
        }
    }
}

// MARK: - RFP Category

enum RFPCategory: String, CaseIterable {
    case venue = "Venue"
    case catering = "Catering"
    case photography = "Photography"
    case videography = "Videography"
    case florals = "Florals"
    case music = "Music/DJ"
    case planner = "Wedding Planner"
    case beauty = "Hair & Makeup"
    case cake = "Cake/Desserts"
    case transportation = "Transportation"
    case rentals = "Rentals"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .venue: return "building.2.fill"
        case .catering: return "fork.knife"
        case .photography: return "camera.fill"
        case .videography: return "video.fill"
        case .florals: return "leaf.fill"
        case .music: return "music.note"
        case .planner: return "calendar"
        case .beauty: return "paintbrush.fill"
        case .cake: return "birthday.cake.fill"
        case .transportation: return "car.fill"
        case .rentals: return "chair.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .venue: return "8B5CF6"
        case .catering: return "22C55E"
        case .photography: return "FF6B35"
        case .videography: return "EF4444"
        case .florals: return "10B981"
        case .music: return "F59E0B"
        case .planner: return "3B82F6"
        case .beauty: return "EC4899"
        case .cake: return "F472B6"
        case .transportation: return "6366F1"
        case .rentals: return "8B5CF6"
        case .other: return "6B7280"
        }
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let days = Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "1 day ago" }
        return "\(days) days ago"
    }
}
