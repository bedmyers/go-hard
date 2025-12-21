//
//  ProjectsViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 11/17/25.
//

import SwiftUI

@MainActor
class ProjectsViewModel: ObservableObject {
    @Published var ownedProjects: [Project] = []
    @Published var vendorProjects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    
    // MARK: - Computed Properties

    var pendingInvitations: [Project] {
        vendorProjects.filter { $0.myVendorRole?.isPending == true }
    }

    var acceptedVendorProjects: [Project] {
        vendorProjects.filter { $0.myVendorRole?.isPending != true }
    }

    var allProjects: [Project] {
        ownedProjects + acceptedVendorProjects
    }
    
    var totalProjects: Int {
        allProjects.count
    }
    
    var totalInEscrow: Double {
        var total = 0
        for project in allProjects {
            for vendor in project.vendors {
                total += vendor.escrow?.amountCents ?? 0
            }
        }
        return Double(total) / 100.0
    }
    
    var projectsDueSoon: Int {
        allProjects.filter { project in
            guard let eventDate = project.eventDate else { return false }
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: eventDate).day ?? 0
            return daysUntil <= 30 && daysUntil >= 0
        }.count
    }
    
    // MARK: - API Methods
    
    func fetchProjects() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: ProjectsResponse = try await api.getProjects()
            
            self.ownedProjects = response.ownedProjects
            self.vendorProjects = response.vendorProjects
            
            print("Loaded \(ownedProjects.count) owned projects")
            print("Loaded \(vendorProjects.count) vendor projects")
            
            if ownedProjects.isEmpty && vendorProjects.isEmpty {
                print("No projects found - this is expected for new accounts")
            }
            
        } catch {
            errorMessage = "Failed to load projects: \(error.localizedDescription)"
            print("Error fetching projects:", error)
        }
        
        isLoading = false
    }
    
    func createProject(
        title: String,
        description: String?,
        totalBudget: Int?,
        eventDate: Date?,
        location: String?,
        pinterestBoard: String? = nil
    ) async throws {
        print("Creating project: \(title)")
        
        var body: [String: Any] = ["title": title]
        
        if let description = description { body["description"] = description }
        if let totalBudget = totalBudget { body["totalBudget"] = totalBudget }
        if let location = location { body["location"] = location }
        if let pinterestBoard = pinterestBoard { body["pinterestBoard"] = pinterestBoard }
        if let eventDate = eventDate {
            let formatter = ISO8601DateFormatter()
            body["eventDate"] = formatter.string(from: eventDate)
        }
        
        let newProject: Project = try await api.createProject(body: body)
        
        // Add to local state
        ownedProjects.insert(newProject, at: 0)
        
        print("Created project: \(newProject.title) (ID: \(newProject.id))")
    }
    
    func deleteProject(_ projectId: Int) async throws {
        try await api.deleteProject(projectId)

        // Remove from local state
        ownedProjects.removeAll { $0.id == projectId }
        vendorProjects.removeAll { $0.id == projectId }

        print("Deleted project: \(projectId)")
    }

    // MARK: - Agreement Actions

    func acceptAgreement(projectVendorId: Int) async throws {
        let _ = try await api.acceptAgreement(projectVendorId: projectVendorId)
        print("✅ Accepted agreement: \(projectVendorId)")
        await fetchProjects()
    }

    func declineAgreement(projectVendorId: Int) async throws {
        let _ = try await api.declineAgreement(projectVendorId: projectVendorId)
        print("❌ Declined agreement: \(projectVendorId)")
        await fetchProjects()
    }
}
