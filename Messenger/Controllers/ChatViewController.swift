//
//  ChatViewController.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 25/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseAuth

struct Message: MessageType {
    
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    
}

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

struct Sender: SenderType {
    
    var senderId: String
    var displayName: String
    var photoURL: String
    
    
}

class ChatViewController: MessagesViewController {
    
    public var isNewConversation = false
    public let otherUserID: String
    private let conversationID: String?
    
    private var messages = [Message]()
    private var currentUser = Sender(senderId: UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID)!,
                                     displayName: "Abdulaziz",
                                     photoURL: "")
    

    init(userID: String, conversationID: String?) {
        otherUserID = userID
        self.conversationID = conversationID
        super.init(nibName: nil, bundle: nil)
        
        if let conversationID = self.conversationID {
            startListeningForMessages(forConversationID: conversationID)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func startListeningForMessages(forConversationID conversationID: String) {
        DatabaseManager.shared.getAllMessages(forConversationID: conversationID) { [unowned self] (result) in
            switch result {
                case .success(let messages):
                    guard !messages.isEmpty else { return }
                
                    self.messages = messages
                
                    DispatchQueue.main.async {
                        self.messagesCollectionView.reloadDataAndKeepOffset()
                    }
                case .failure(let error):
                    print("Failed to get messages: \(error)")
            }
        }
    }
    

}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else { return }
        
        print("Sending: \(text)")
        
        if isNewConversation {
            // Create a new conversation in the database
            let message = Message(sender: currentUser, messageId: createMessageID(), sentDate: Date(), kind: .text(text))
            
            DatabaseManager.shared.createNewConversation(withUserID: otherUserID, name: title ?? "User", firstMessage: message) { (success) in
                if success {
                    print("message sent")
                } else {
                    print("failed to send message")
                }
            }
        } else {
            // Append to the existing conversation
        }
    }
    
    private func createMessageID() -> String {
        // date, otherUserID, currentUserID, UUID
        let id = "\(UUID().uuidString)_\(Date().timeIntervalSinceReferenceDate)"
            .replacingOccurrences(of: " ", with: "-")
            .safeForDatabaseReferenceChild()
        print("created message ID: \(id)")
        return id
    }
}
