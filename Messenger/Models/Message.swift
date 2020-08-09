//
//  Message.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 09/08/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import MessageKit

struct Message: MessageType {
    
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    
}
