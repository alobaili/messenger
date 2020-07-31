//
//  Conversation.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 31/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

struct Conversation {
    
    let id: String
    var name: String
    var otherUserID: String
    var latestMessage: LatestMessage
    
}

struct LatestMessage {
    
    var date: String
    var isRead: Bool
    var message: String
    
    
}
