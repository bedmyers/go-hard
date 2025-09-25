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
    
    // Custom init to handle decoding from API (since avatarImageName won't come from backend)
    init(id: Int, email: String, name: String, avatarImageName: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarImageName = avatarImageName
    }
    
    // Custom CodingKeys to exclude avatarImageName from API encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id, email, name
    }
    
    // Custom decoder that only decodes the API fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        avatarImageName = nil // Always nil when coming from API
    }
    
    // Custom encoder that only encodes the API fields
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
        // Don't encode avatarImageName since it's client-side only
    }
}
