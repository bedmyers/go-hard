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

struct AcceptAgreementResponse: Codable {
    let success: Bool
    let message: String
}

struct GenericSuccessResponse: Codable {
    let success: Bool
    let message: String
}
