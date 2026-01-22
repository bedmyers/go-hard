//
//  RFPViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 11/28/25.
//

import SwiftUI

@MainActor
class RFPDetailViewModel: ObservableObject {
    @Published var rfp: RFP
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showAcceptConfirm = false
    @Published var selectedBid: Bid?
    
    private let api = APIService.shared
    
    init(rfp: RFP) {
        self.rfp = rfp
    }
    
    func refresh() async {
        isLoading = true
        
        do {
            rfp = try await api.getRFP(rfp.id)
            print("✅ Refreshed RFP: \(rfp.bidCount) bids")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error refreshing RFP: \(error)")
        }
        
        isLoading = false
    }
    
    func acceptBid(_ bid: Bid) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await api.acceptBid(bidId: bid.id)
            print("✅ Bid accepted, ProjectVendor created: \(result.projectVendor.id)")
            
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error accepting bid: \(error)")
        }
        
        isLoading = false
    }
    
    func closeRFP() async {
        isLoading = true
        errorMessage = nil

        do {
            rfp = try await api.updateRFP(rfpId: rfp.id, body: ["status": "CLOSED"])
            print("✅ RFP closed")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error closing RFP: \(error)")
        }

        isLoading = false
    }

    func updateRFP(_ updatedRFP: RFP) {
        self.rfp = updatedRFP
    }
}
