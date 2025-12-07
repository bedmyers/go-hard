//
//  ProjectsResponse.swift
//  Goldy
//
//  Created by Blair Myers on 11/17/25.
//

import Foundation

struct ProjectsResponse: Codable {
    let ownedProjects: [Project]
    let vendorProjects: [Project]
}
