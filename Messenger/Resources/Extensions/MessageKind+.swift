//
//  MessageKind+.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 09/08/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import MessageKit

extension MessageKind: CustomStringConvertible {
    
    public var description: String {
        switch self {
            case .text: return "text"
            case .attributedText: return "attributed_text"
            case .photo: return "photo"
            case .video: return "video"
            case .location: return "location"
            case .emoji: return "emoji"
            case .audio: return "audio"
            case .contact: return "contact"
            case .custom: return "custom"
        }
    }
    
    
}
