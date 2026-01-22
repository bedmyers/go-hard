//
//  User.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import Foundation

struct User: Identifiable, Codable, Hashable {
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
    
    // New vendor profile fields
    let profileImageUrl: String?
    let startingPrice: Int?  // in cents
    let instagramHandle: String?
    let websiteUrl: String?
    let yearsInBusiness: Int?
    
    var avatarImageName: String? = nil
    
    enum UserType: String, Codable {
        case customer = "CUSTOMER"
        case vendor = "VENDOR"
        case both = "BOTH"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, userType
        case bio, services, portfolioUrls, location, phoneNumber, stripeAccountId
        case profileImageUrl, startingPrice, instagramHandle, websiteUrl, yearsInBusiness
    }
    
    // MARK: - Computed Properties
    
    var startingPriceFormatted: String? {
        guard let price = startingPrice else { return nil }
        return "$\(price / 100)+"
    }
    
    var instagramUrl: URL? {
        guard let handle = instagramHandle, !handle.isEmpty else { return nil }
        let cleanHandle = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
        return URL(string: "https://instagram.com/\(cleanHandle)")
    }
    
    var websiteUrlParsed: URL? {
        guard let urlString = websiteUrl, !urlString.isEmpty else { return nil }
        if urlString.hasPrefix("http") {
            return URL(string: urlString)
        }
        return URL(string: "https://\(urlString)")
    }
    
    var experienceText: String? {
        guard let years = yearsInBusiness else { return nil }
        return years == 1 ? "1 year experience" : "\(years) years experience"
    }
    
    var isVerified: Bool {
        stripeAccountId != nil && !stripeAccountId!.isEmpty
    }
    
    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    // MARK: - Initializers
    
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
        profileImageUrl: String? = nil,
        startingPrice: Int? = nil,
        instagramHandle: String? = nil,
        websiteUrl: String? = nil,
        yearsInBusiness: Int? = nil,
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
        self.profileImageUrl = profileImageUrl
        self.startingPrice = startingPrice
        self.instagramHandle = instagramHandle
        self.websiteUrl = websiteUrl
        self.yearsInBusiness = yearsInBusiness
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
        
        // New fields
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        startingPrice = try container.decodeIfPresent(Int.self, forKey: .startingPrice)
        instagramHandle = try container.decodeIfPresent(String.self, forKey: .instagramHandle)
        websiteUrl = try container.decodeIfPresent(String.self, forKey: .websiteUrl)
        yearsInBusiness = try container.decodeIfPresent(Int.self, forKey: .yearsInBusiness)
        
        avatarImageName = nil
    }
}
