//
//  VendorCategory.swift
//  Goldy
//
//  Vendor service categories used for browsing and search
//

import SwiftUI

enum VendorCategory: String, CaseIterable, Identifiable {
    case photographer
    case videographer
    case florist
    case catering
    case dj
    case band
    case cake
    case venue
    case planner
    case officiant
    case hair
    case makeup
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .photographer: return "Photo"
        case .videographer: return "Video"
        case .florist: return "Florist"
        case .catering: return "Catering"
        case .dj: return "DJ"
        case .band: return "Band"
        case .cake: return "Cake"
        case .venue: return "Venue"
        case .planner: return "Planner"
        case .officiant: return "Officiant"
        case .hair: return "Hair"
        case .makeup: return "Makeup"
        }
    }
    
    var icon: String {
        switch self {
        case .photographer: return "camera"
        case .videographer: return "video"
        case .florist: return "leaf"
        case .catering: return "fork.knife"
        case .dj: return "music.note"
        case .band: return "music.mic"
        case .cake: return "birthday.cake"
        case .venue: return "building.columns"
        case .planner: return "calendar"
        case .officiant: return "book.closed"
        case .hair: return "scissors"
        case .makeup: return "paintbrush"
        }
    }
    
    var searchTerm: String {
        rawValue
    }
}
