//
//  RFPListViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 11/28/25.
//

import SwiftUI

@MainActor
class RFPListViewModel: ObservableObject {
    @Published var rfps: [RFP] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    
    func loadRFPs(projectId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            rfps = try await api.getRFPsForProject(projectId)
            print("✅ Loaded \(rfps.count) RFPs")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading RFPs: \(error)")
        }

        isLoading = false
    }

    func closeRFP(_ rfp: RFP) async {
        do {
            _ = try await api.updateRFP(rfpId: rfp.id, body: ["status": "CLOSED"])
            print("✅ RFP closed: \(rfp.id)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error closing RFP: \(error)")
        }
    }
}
