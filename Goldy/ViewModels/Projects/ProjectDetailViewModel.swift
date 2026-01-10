//
//  ProjectDetailViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 11/25/25.
//

import SwiftUI

@MainActor
class ProjectDetailViewModel: ObservableObject {
    @Published var project: Project
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    
    init(project: Project) {
        self.project = project
    }
    
    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            project = try await api.getProject(project.id)
            print("✅ Refreshed project: \(project.vendors.count) vendors")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error refreshing project: \(error)")
        }

        isLoading = false
    }

    func archiveProject() async {
        do {
            _ = try await api.updateProject(
                projectId: project.id,
                body: ["status": "CANCELED"]
            )
            print("✅ Project archived")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error archiving project: \(error)")
        }
    }
}
