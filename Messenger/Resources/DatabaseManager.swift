//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 23/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import MessageKit

final class DatabaseManager {
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    let iso8601DateFormatter = ISO8601DateFormatter()
    
    let encoder = JSONEncoder()
    
    
    private init() {
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    
}

// MARK: - Account Management

extension DatabaseManager {
    
    public func insertUser(_ user: MessengerUser, completion: @escaping (Bool) -> Void) {
        do {
            let userData = try encoder.encode(user)
            let userDictionary = try JSONSerialization.jsonObject(with: userData, options: .allowFragments) as! [String: Any]
            database.child("users").child(user.id.safeForDatabaseReferenceChild()).setValue(userDictionary) { (error, databaseReference) in
                if let error = error {
                    print("Failed to insert the user into the database: \(error)")
                    completion(false)
                    return
                }
                
                completion(true)
            }
        } catch {
            fatalError("\(error)")
        }
    }
    
    public func userExists(withID id: String, completion: @escaping (Bool) -> Void) {
        database.child("users").child(id.safeForDatabaseReferenceChild()).observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot.exists())
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[Dictionary<String, [String : Any]>.Element],Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: [String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let users = value.sorted { (lhs, rhs) -> Bool in
                let lhsFirstName = lhs.value["first_name"] as! String
                let rhsFirstName = rhs.value["first_name"] as! String
                return lhsFirstName < rhsFirstName
            }
            
            completion(.success(users))
        }
    }
    
}

// MARK: - Sending Messages / Conversations

extension DatabaseManager {
    
    public func createNewConversation(withUserID userID: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentUserID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID) else {
            return
        }
        
        let safeCurrentUserID = currentUserID.safeForDatabaseReferenceChild()
        
        let reference = database.child("users").child(safeCurrentUserID)
        
        reference.observeSingleEvent(of: .value) { [unowned self] (snapshot) in
            guard snapshot.exists(), var user = snapshot.value as? [String: Any] else {
                print("User ID '\(safeCurrentUserID)' was not found.")
                completion(false)
                return
            }
            
            var message = ""
            
            switch firstMessage.kind {
                case .text(let messageText):
                    message = messageText
                case .attributedText(_):
                    break
                case .photo(_):
                    break
                case .video(_):
                    break
                case .location(_):
                    break
                case .emoji(_):
                    break
                case .audio(_):
                    break
                case .contact(_):
                    break
                case .custom(_):
                    break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversation: [String: Any] = [
                "id": conversationID,
                "other_user_id": userID.safeForDatabaseReferenceChild(),
                "name": name,
                "latest_message": [
                    "date": self.iso8601DateFormatter.string(from: firstMessage.sentDate),
                    "is_read": false,
                    "message": message
                ],
            ]
            
            let recipientNewConversation: [String: Any] = [
                "id": conversationID,
                "other_user_id": safeCurrentUserID,
                "name": Auth.auth().currentUser!.displayName!,
                "latest_message": [
                    "date": self.iso8601DateFormatter.string(from: firstMessage.sentDate),
                    "is_read": false,
                    "message": message
                ],
            ]
            
            // Update recipient user conversations array
            self.database.child("users").child("\(userID.safeForDatabaseReferenceChild())/conversations")
                .observeSingleEvent(of: .value) { [unowned self] (snapshot) in
                    if var conversations = snapshot.value as? [[String: Any]] {
                        // conversations array for current user
                        // append the new conversation to it
                        conversations.append(recipientNewConversation)
                        self.database.child("users")
                            .child("\(userID.safeForDatabaseReferenceChild())/conversations")
                            .setValue(conversations)
                    } else {
                        // conversations array doesn't exists
                        // create it
                        self.database.child("users")
                            .child("\(userID.safeForDatabaseReferenceChild())/conversations")
                            .setValue([recipientNewConversation])
                    }
                }
            
            // Update current user conversations array
            if var conversations = user["conversations"] as? [[String: Any]] {
                // conversations array for current user
                // append the new conversation to it
                conversations.append(newConversation)
                user["conversations"] = conversations
            } else {
                // conversations array doesn't exists
                // create it
                user["conversations"] = [ newConversation ]
            }
            
            reference.setValue(user) { [unowned self] (error, _) in
                if let error = error {
                    print("Failed to create a new conversations array for \(safeCurrentUserID): \(error)")
                    completion(false)
                    return
                }
                
                self.finishCreatingConversation(withID: conversationID,
                                                name: name,
                                                firstMessage: firstMessage,
                                                completion: completion)
            }
        }
    }
    
    private func finishCreatingConversation(withID conversationID: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        var content = ""
        
        switch firstMessage.kind {
            case .text(let messageText):
                content = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
        }
        
        let senderID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID)!
        
        let message: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.description,
            "content": content,
            "date": iso8601DateFormatter.string(from: firstMessage.sentDate),
            "sender_id": senderID,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [message]
        ]
        
        database.child("\(conversationID)").setValue(value) { (error, _) in
            if let error = error {
                print("Failed to create conversation with ID \(conversationID): \(error)")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    public func getAllConversations(forUserID userID: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("users/\(userID.safeForDatabaseReferenceChild())/conversations").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationID = dictionary["id"] as? String,
                let name = dictionary["name"] as? String,
                let otherUserID = dictionary["other_user_id"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String: Any],
                let date = latestMessage["date"] as? String,
                let isRead = latestMessage["is_read"] as? Bool,
                let massage = latestMessage["message"] as? String
                    else {
                        return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, isRead: isRead, message: massage)
                let conversation = Conversation(id: conversationID,
                                                name: name,
                                                otherUserID: otherUserID,
                                                latestMessage: latestMessageObject)
                return conversation
            }
            
            completion(.success(conversations))
        }
    }
    
    public func getAllMessages(forConversationID conversationID: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(conversationID.safeForDatabaseReferenceChild())/messages").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap { dictionary in
                guard let content = dictionary["content"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let date = self.iso8601DateFormatter.date(from: dateString),
                    let messageID = dictionary["id"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let name = dictionary["name"] as? String,
                    let senderID = dictionary["sender_id"] as? String,
                    let type = dictionary["type"] as? String
                    else {
                        return nil
                }
                
                let sender = Sender(senderId: senderID, displayName: name, photoURL: "")
                
                let message = Message(sender: sender,
                                      messageId: messageID,
                                      sentDate: date,
                                      kind: .text(content))
                return message
            }
            
            completion(.success(messages))
        }
    }
    
    public func sendMessage(_ message: Message, recipientID: String, conversationID: String, name: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID) else {
            completion(false)
            return
        }
        
        // Add the new message to the messages array of the passed conversation ID
        database.child("\(conversationID.safeForDatabaseReferenceChild())/messages").observeSingleEvent(of: .value) { [unowned self] (snapshot) in
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            var content = ""
            
            switch message.kind {
                case .text(let messageText):
                    content = messageText
                case .attributedText(_):
                    break
                case .photo(_):
                    break
                case .video(_):
                    break
                case .location(_):
                    break
                case .emoji(_):
                    break
                case .audio(_):
                    break
                case .contact(_):
                    break
                case .custom(_):
                    break
            }
            
            let senderID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID)!
            
            let newMessage: [String: Any] = [
                "id": message.messageId,
                "type": message.kind.description,
                "content": content,
                "date": self.iso8601DateFormatter.string(from: message.sentDate),
                "sender_id": senderID,
                "is_read": false,
                "name": name
            ]
            
            currentMessages.append(newMessage)
            
            self.database.child("\(conversationID.safeForDatabaseReferenceChild())/messages").setValue(currentMessages) { (error, _) in
                if let error = error {
                    print("Failed to updated messages array for conversation: \(conversationID.safeForDatabaseReferenceChild()): \(error)")
                    completion(false)
                    return
                }
                
                let newLatestMessage: [String: Any] = [
                    "date": self.iso8601DateFormatter.string(from: message.sentDate),
                    "is_read": false,
                    "message": content
                ]
                
                // Update the sender's latest message
                self.database.child("users").child("\(currentUserID.safeForDatabaseReferenceChild())/conversations").observeSingleEvent(of: .value) { (snapshot) in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    if let conversationIndex = currentUserConversations.firstIndex(where: { ($0["id"] as! String) == conversationID }) {
                        currentUserConversations[conversationIndex]["latest_message"] = newLatestMessage
                        
                        self.database
                            .child("users")
                            .child("\(currentUserID.safeForDatabaseReferenceChild())/conversations")
                            .setValue(currentUserConversations) { (error, _) in
                                if let error = error {
                                    print(error)
                                    completion(false)
                                    return
                                }
                                
                                // Update the recipient's latest message
                                self.database.child("users").child("\(recipientID.safeForDatabaseReferenceChild())/conversations").observeSingleEvent(of: .value) { (snapshot) in
                                    guard var recipientConversations = snapshot.value as? [[String: Any]] else {
                                        completion(false)
                                        return
                                    }
                                    
                                    if let conversationIndex = recipientConversations.firstIndex(where: { ($0["id"] as! String) == conversationID }) {
                                        recipientConversations[conversationIndex]["latest_message"] = newLatestMessage
                                        
                                        self.database
                                            .child("users")
                                            .child("\(recipientID.safeForDatabaseReferenceChild())/conversations")
                                            .setValue(recipientConversations) { (error, _) in
                                                if let error = error {
                                                    print(error)
                                                    completion(false)
                                                    return
                                                }
                                                completion(true)
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
    
    
}
