//
//  ChatViewController.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 25/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import MessageKit

struct Message: MessageType {
    
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    
}

struct Sender: SenderType {
    
    var senderId: String
    var displayName: String
    var photoURL: String
}

class ChatViewController: MessagesViewController {
    
    private var messages = [Message]()
    private var dummySender = Sender(senderId: "1", displayName: "Abdulaziz", photoURL: "")
    private var dummyReceiver = Sender(senderId: "2", displayName: "Max", photoURL: "")
    

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        appendDummyMessages()
    }
    
    private func appendDummyMessages() {
        messages = [
            Message(sender: dummySender, messageId: "1", sentDate: Date(), kind: .text("Hello")),
            Message(sender: dummyReceiver, messageId: "2", sentDate: Date().addingTimeInterval(5), kind: .text("Hi"))
        ]
    }
    

}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        dummySender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    
}
