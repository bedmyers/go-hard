//
//  CreateRFPViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 11/28/25.
//

import SwiftUI

@MainActor
class CreateRFPViewModel: ObservableObject {
    // Navigation
    @Published var currentStep = 1
    
    // Step 1: Basics
    @Published var selectedCategory: RFPCategory?
    @Published var title = ""
    @Published var description = ""
    
    // Step 2: Event Details
    @Published var eventDate = Date().addingTimeInterval(86400 * 180) // 6 months out
    @Published var location = ""
    @Published var guestCountText = ""
    
    // Step 3: Style & Inspiration
    @Published var inspirationUrl = ""
    @Published var selectedStyleTags: Set<StyleTag> = []
    
    // Step 4: Requirements
    @Published var mustHaves: [String] = ["", "", ""]
    @Published var niceToHaves: [String] = ["", "", ""]
    
    // Step 5: Budget & Timeline
    @Published var budgetText = ""
    @Published var deadline = Date().addingTimeInterval(86400 * 14) // 2 weeks
    @Published var decisionDate = Date().addingTimeInterval(86400 * 21) // 3 weeks
    
    // Step 6: Visibility
    @Published var visibility: RFP.RFPVisibility = .public
    @Published var invitedVendorIds: [Int] = []
    
    // State
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var didCreate = false
    @Published var createdRFP: RFP?
    
    private let api = APIService.shared
    
    // MARK: - Validation
    
    var canProceed: Bool {
        switch currentStep {
        case 1:
            return !title.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !description.trimmingCharacters(in: .whitespaces).isEmpty
        case 2:
            return !location.trimmingCharacters(in: .whitespaces).isEmpty
        case 3:
            return true // Optional step
        case 4:
            return true // Optional step
        case 5:
            return true // Budget is optional
        case 6:
            return true
        default:
            return true
        }
    }
    
    // MARK: - Computed Properties
    
    var budgetCents: Int? {
        guard !budgetText.isEmpty else { return nil }
        let cleaned = budgetText.replacingOccurrences(of: ",", with: "")
        guard let dollars = Int(cleaned) else { return nil }
        return dollars * 100
    }
    
    var guestCount: Int? {
        guard !guestCountText.isEmpty else { return nil }
        return Int(guestCountText)
    }
    
    var filteredMustHaves: [String] {
        mustHaves.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    
    var filteredNiceToHaves: [String] {
        niceToHaves.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    
    var styleTagStrings: [String] {
        selectedStyleTags.map { $0.rawValue }
    }
    
    // MARK: - Create RFP
    
    func createRFP(projectId: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            var body: [String: Any] = [
                "title": title.trimmingCharacters(in: .whitespaces),
                "description": description.trimmingCharacters(in: .whitespaces),
                "visibility": visibility == .public ? "PUBLIC" : "PRIVATE"
            ]
            
            // Event details
            body["eventDate"] = ISO8601DateFormatter().string(from: eventDate)
            
            if !location.isEmpty {
                body["location"] = location.trimmingCharacters(in: .whitespaces)
            }
            
            if let guestCount = guestCount {
                body["guestCount"] = guestCount
            }
            
            // Style & inspiration
            if !inspirationUrl.isEmpty {
                body["inspirationUrl"] = inspirationUrl.trimmingCharacters(in: .whitespaces)
            }
            
            if !selectedStyleTags.isEmpty {
                body["styleTags"] = styleTagStrings
            }
            
            // Requirements
            if !filteredMustHaves.isEmpty {
                body["mustHaves"] = filteredMustHaves
            }
            
            if !filteredNiceToHaves.isEmpty {
                body["niceToHaves"] = filteredNiceToHaves
            }
            
            // Budget & timeline
            if let budget = budgetCents {
                body["budget"] = budget
            }
            
            body["deadline"] = ISO8601DateFormatter().string(from: deadline)
            body["decisionDate"] = ISO8601DateFormatter().string(from: decisionDate)
            
            // Project ID if provided
            if let projectId = projectId {
                body["projectId"] = projectId
            }
            
            let rfp: RFP
            if let projectId = projectId {
                rfp = try await api.createRFP(projectId: projectId, body: body)
            } else {
                rfp = try await api.createRFP(body: body)
            }
            
            createdRFP = rfp
            didCreate = true
            print("✅ RFP created: \(rfp.id)")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error creating RFP: \(error)")
        }
        
        isLoading = false
    }
}
