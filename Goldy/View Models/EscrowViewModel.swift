//
//  EscrowViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 6/30/25.
//

import Foundation
import Combine

class EscrowViewModel: ObservableObject {
    @Published var projects: [EscrowProject] = []
    @Published var isLoading: Bool = false
    @Published var hasLoadedOnce: Bool = false

    init(projects: [EscrowProject] = []) {
        self.projects = projects
    }

    func loadEscrows(token: String) {
        print("🔄 DEBUG: loadEscrows called - setting isLoading = true")
        isLoading = true
        
        EscrowService.fetchEscrows(token: token) { projects in
            DispatchQueue.main.async {
                print("🔄 DEBUG: fetchEscrows completed with \(projects.count) projects")
                print("🔄 DEBUG: Setting isLoading = false, hasLoadedOnce = true")
                self.projects = projects
                self.isLoading = false
                self.hasLoadedOnce = true
            }
        }
    }

    func addEscrow(_ newEscrow: EscrowProject) {
        DispatchQueue.main.async {
            self.projects.insert(newEscrow, at: 0)
        }
    }
}
