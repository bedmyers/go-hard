//
//  User.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: Int
    let email: String
    let name: String
    let userType: UserType
    
    let bio: String?
    let services: [String]?
    let portfolioUrls: [String]?
    let location: String?
    let phoneNumber: String?
    let stripeAccountId: String?
    
    var avatarImageName: String? = nil
    
    enum UserType: String, Codable {
        case customer = "CUSTOMER"
        case vendor = "VENDOR"
        case both = "BOTH"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, userType
        case bio, services, portfolioUrls, location, phoneNumber, stripeAccountId
    }
    
    init(
        id: Int,
        email: String,
        name: String,
        userType: UserType = .customer,
        bio: String? = nil,
        services: [String]? = nil,
        portfolioUrls: [String]? = nil,
        location: String? = nil,
        phoneNumber: String? = nil,
        stripeAccountId: String? = nil,
        avatarImageName: String? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.userType = userType
        self.bio = bio
        self.services = services
        self.portfolioUrls = portfolioUrls
        self.location = location
        self.phoneNumber = phoneNumber
        self.stripeAccountId = stripeAccountId
        self.avatarImageName = avatarImageName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        userType = try container.decodeIfPresent(UserType.self, forKey: .userType) ?? .customer
        
        // Decode optional vendor fields
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        services = try container.decodeIfPresent([String].self, forKey: .services)
        portfolioUrls = try container.decodeIfPresent([String].self, forKey: .portfolioUrls)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        stripeAccountId = try container.decodeIfPresent(String.self, forKey: .stripeAccountId)
        
        avatarImageName = nil
    }
}
