//
//  Messages.swift
//  Goldy
//
//  Created by Blair Myers on 12/7/25.
//

import Foundation

struct Message: Codable, Identifiable {
    let id: Int
    let senderId: Int
    let receiverId: Int
    let content: String
    let read: Bool
    let createdAt: Date
    let sender: MessageUser?
    
    var isFromCurrentUser: Bool {
        guard let currentUserId = UserDefaults.standard.object(forKey: "userId") as? Int else {
            return false
        }
        return senderId == currentUserId
    }
    
    var timeDisplay: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(createdAt) {
            return createdAt.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            return createdAt.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

struct MessageUser: Codable {
    let id: Int
    let name: String
    let userType: String?
}

struct Conversation: Codable, Identifiable {
    let partner: MessageUser
    let lastMessage: Message
    let unreadCount: Int
    
    var id: Int { partner.id }
}
