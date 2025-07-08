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

    init(projects: [EscrowProject] = []) {
        self.projects = projects
    }
    
    func loadEscrows(token: String) {
        fetchEscrows(token: token) { projects in
            self.projects = projects
        }
    }
    
    func addEscrow(_ newEscrow: EscrowProject) {
        DispatchQueue.main.async {
            self.projects.insert(newEscrow, at: 0)
        }
    }
}
