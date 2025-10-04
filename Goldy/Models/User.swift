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
    
    init(id: Int, email: String, name: String, avatarImageName: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarImageName = avatarImageName
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email, name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        avatarImageName = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
    }
}
