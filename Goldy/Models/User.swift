//
//  User.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

struct User: Identifiable, Codable {
    let id: Int
    let email: String
    let name: String
    var avatarImageName: String? = nil
}
