//
//  Conversation.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 31/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

struct Conversation: Codable, Hashable {
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    var name: String
    var otherUserID: String
    var latestMessage: LatestMessage
    
    enum CodingKeys: String, CodingKey {
        case id, name, latestMessage
        case otherUserID = "otherUserId"
    }
    
}

struct LatestMessage: Codable, Hashable {
    
    var date: String
    var isRead: Bool
    var message: String
    
    
}
