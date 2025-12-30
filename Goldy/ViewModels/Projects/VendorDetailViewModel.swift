//
//  VendorDetailViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 11/25/25.
//

import SwiftUI

@MainActor
class VendorDetailViewModel: ObservableObject {
    @Published var projectVendor: ProjectVendor
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showContactOptions = false
    @Published var showFundEscrow = false
    @Published var showTerms = false
    @Published var selectedMilestone: Milestone?
    @Published var showRemoveConfirm = false
    @Published var didRemoveVendor = false

    private let api = APIService.shared
    
    init(projectVendor: ProjectVendor) {
        self.projectVendor = projectVendor
    }
    
    var paymentProgress: (released: Double, inEscrow: Double, pending: Double, total: Double, percentage: CGFloat) {
        guard let escrow = projectVendor.escrow else {
            return (0, 0, 0, Double(projectVendor.amountCents) / 100.0, 0)
        }
        
        let milestones = escrow.milestones
        let total = Double(projectVendor.amountCents) / 100.0
        
        let released = Double(milestones.filter { $0.released }.reduce(0) { $0 + $1.amountCents }) / 100.0
        
        let isFunded = escrow.status == "AUTHORIZED" || escrow.status == "FUNDED" || escrow.status == "COMPLETE"
        let inEscrow = isFunded ? (total - released) : 0
        let pending = isFunded ? 0 : (total - released)
        
        let percentage = total > 0 ? CGFloat(released / total) : 0
        
        return (released, inEscrow, pending, total, percentage)
    }
    
    func fundEscrow() async {
        guard let escrow = projectVendor.escrow else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await api.fundEscrow(escrowId: escrow.id, paymentMethodId: "pm_card_visa")
            print("✅ Escrow funded: \(response.status)")
            
            await refreshEscrow()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error funding escrow: \(error)")
        }
        
        isLoading = false
    }
    
    func releaseMilestone(_ milestone: Milestone) async {
        guard let escrow = projectVendor.escrow else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await api.releaseMilestone(escrowId: escrow.id, milestoneId: milestone.id)
            print("✅ Milestone released: \(response.amountCaptured)")
            
            await refreshEscrow()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error releasing milestone: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await refreshEscrow()
    }

    var canRemoveVendor: Bool {
        // Can only remove if escrow hasn't been funded
        guard let escrow = projectVendor.escrow else { return true }
        return escrow.status == "PENDING"
    }

    func removeVendor() async {
        isLoading = true
        errorMessage = nil

        do {
            let _ = try await api.removeVendorFromProject(
                projectId: projectVendor.projectId,
                vendorId: projectVendor.vendorId
            )
            print("✅ Vendor removed")
            didRemoveVendor = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error removing vendor: \(error)")
        }

        isLoading = false
    }

    private func refreshEscrow() async {
        guard let escrow = projectVendor.escrow else { return }
        
        do {
            let updated = try await api.getEscrow(escrow.id)
            
            var updatedVendor = projectVendor
            updatedVendor = ProjectVendor(
                id: projectVendor.id,
                projectId: projectVendor.projectId,
                vendorId: projectVendor.vendorId,
                vendor: projectVendor.vendor,
                role: projectVendor.role,
                description: projectVendor.description,
                amountCents: projectVendor.amountCents,
                dueDate: projectVendor.dueDate,
                status: projectVendor.status,
                escrow: updated,
                createdAt: projectVendor.createdAt,
                updatedAt: projectVendor.updatedAt
            )
            
            self.projectVendor = updatedVendor
        } catch {
            print("❌ Error refreshing escrow: \(error)")
        }
    }
}
