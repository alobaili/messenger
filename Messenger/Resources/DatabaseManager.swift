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
    let decoder = JSONDecoder()
    
    
    private init() {
        encoder.keyEncodingStrategy = .convertToSnakeCase
        decoder.keyDecodingStrategy = .convertFromSnakeCase
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
    
    public func getAllUsers(completion: @escaping (Result<[MessengerUser],Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: [String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            do {
                let usersData = try JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
                print(String(data: usersData, encoding: .utf8)!)
                var messengerUserArray = try self.decoder.decode(MessengerUserArray.self, from: usersData)
                
                let currentUserID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID)?.safeForDatabaseReferenceChild()
                
                messengerUserArray.messengerUsers.removeAll { $0.id == currentUserID }
                
                let sortedUsers = messengerUserArray.messengerUsers.sorted(by: { (lhs, rhs) -> Bool in
                    if let lFirstName = lhs.firstName, let rFirstName = rhs.firstName {
                        return lFirstName < rFirstName
                    } else if let lLastName = lhs.lastName, let rLastName = rhs.lastName {
                        return lLastName < rLastName
                    } else {
                        return lhs.id < rhs.id
                    }
                })
                
                completion(.success(sortedUsers))
            } catch {
                print("Failed to decode users: \(error)")
            }
        }
    }
    
    
}

// MARK: - Sending Messages / Conversations

extension DatabaseManager {
    
    public func getConversation(withRecipientID recipientID: String, completion: @escaping (String?) -> Void) {
        guard let senderID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID) else {
            completion(nil)
            return
        }
        
        database.child("users").child("\(recipientID.safeForDatabaseReferenceChild())/conversations").observeSingleEvent(of: .value) { (snapshot) in
            guard let recipientConversations = snapshot.value as? [[String: Any]] else {
                completion(nil)
                return
            }
            
            // Among the recipient's conversations, find the one where the other party is the currently logged in user.
            if let conversation = recipientConversations.first(where: {
                guard let targetSenderID = $0["other_user_id"] as? String else {
                    return false
                }
                
                return targetSenderID == senderID.safeForDatabaseReferenceChild()
            }) {
                // The conversation was found, complete with its ID.
                guard let id = conversation["id"] as? String else {
                    completion(nil)
                    return
                }
                
                completion(id)
            } else {
                // The conversation wasn't found, complete with a failure.
                completion(nil)
            }
        }
    }
    
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
    
    public func getAllConversations(forUserID userID: String, completion: @escaping ([Conversation]) -> Void) {
        database.child("users/\(userID.safeForDatabaseReferenceChild())/conversations").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion([])
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
            
            completion(conversations)
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
                    let typeString = dictionary["type"] as? String
                    else {
                        return nil
                }
                
                let sender = Sender(senderId: senderID, displayName: name, photoURL: "")
                
                var kind: MessageKind?
                
                switch typeString {
                    case "text": kind = .text(content)
                    case "photo":
                        let media = Media(url: URL(string: content),
                                          image: nil,
                                          placeholderImage: UIImage(systemName: "plus")!,
                                          size: CGSize(width: 300, height: 300))
                        kind = .photo(media)
                    case "video":
                        let media = Media(url: URL(string: content),
                                          image: nil,
                                          placeholderImage: UIImage(systemName: "play.rectangle.fill")!,
                                          size: CGSize(width: 300, height: 300))
                        kind = .video(media)
                    default: break
                }
                
                guard let finalKind = kind else { return nil }
                
                let message = Message(sender: sender,
                                      messageId: messageID,
                                      sentDate: date,
                                      kind: finalKind)
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
                case .photo(let media):
                    if let urlString = media.url?.absoluteString {
                        content = urlString
                    }
                case .video(let media):
                    if let urlString = media.url?.absoluteString {
                        content = urlString
                    }
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
                    var updatedCurrentUserConversations = [[String: Any]]()
                    
                    if var currentUserConversations = snapshot.value as? [[String: Any]] {
                        if let conversationIndex = currentUserConversations.firstIndex(where: { ($0["id"] as! String) == conversationID }) {
                            currentUserConversations[conversationIndex]["latest_message"] = newLatestMessage
                            updatedCurrentUserConversations = currentUserConversations
                        } else {
                            let newConversation: [String: Any] = [
                                "id": conversationID,
                                "other_user_id": recipientID.safeForDatabaseReferenceChild(),
                                "name": name,
                                "latest_message": newLatestMessage,
                            ]
                            currentUserConversations.append(newConversation)
                            updatedCurrentUserConversations = currentUserConversations
                        }
                    } else {
                        updatedCurrentUserConversations = [
                            [
                                "id": conversationID,
                                "other_user_id": recipientID.safeForDatabaseReferenceChild(),
                                "name": name,
                                "latest_message": newLatestMessage,
                            ]
                        ]
                    }
                    
                    self.database
                        .child("users")
                        .child("\(currentUserID.safeForDatabaseReferenceChild())/conversations")
                        .setValue(updatedCurrentUserConversations) { (error, _) in
                            if let error = error {
                                print(error)
                                completion(false)
                                return
                            }
                            
                            // Update the recipient's latest message
                            self.database.child("users").child("\(recipientID.safeForDatabaseReferenceChild())/conversations").observeSingleEvent(of: .value) { (snapshot) in
                                
                                var updatedRecipientConversations = [[String: Any]]()
                                
                                if var recipientConversations = snapshot.value as? [[String: Any]] {
                                    if let conversationIndex = recipientConversations.firstIndex(where: { ($0["id"] as! String) == conversationID }) {
                                        recipientConversations[conversationIndex]["latest_message"] = newLatestMessage
                                        updatedRecipientConversations = recipientConversations
                                    } else {
                                        let newConversation: [String: Any] = [
                                            "id": conversationID,
                                            "other_user_id": currentUserID.safeForDatabaseReferenceChild(),
                                            "name": Auth.auth().currentUser!.displayName!,
                                            "latest_message": newLatestMessage,
                                        ]
                                        recipientConversations.append(newConversation)
                                        updatedRecipientConversations = recipientConversations
                                    }
                                } else {
                                    let newConversation: [String: Any] = [
                                        "id": conversationID,
                                        "other_user_id": currentUserID.safeForDatabaseReferenceChild(),
                                        "name": Auth.auth().currentUser!.displayName!,
                                        "latest_message": newLatestMessage,
                                    ]
                                    updatedRecipientConversations = [newConversation]
                                }
                                
                                self.database
                                    .child("users")
                                    .child("\(recipientID.safeForDatabaseReferenceChild())/conversations")
                                    .setValue(updatedRecipientConversations) { (error, _) in
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
    
    public func deleteConversation(_ conversation: Conversation) {
        guard let currentUserID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID) else {
            return
        }
        
        let reference = database.child("users/\(currentUserID.safeForDatabaseReferenceChild())/conversations")
        
        reference.observeSingleEvent(of: .value) { (snapshot) in
            guard var conversations = snapshot.value as? [[String: Any]] else {
                return
            }
            
            if let indexToRemove = conversations.firstIndex(where: { ($0["id"] as! String) == conversation.id }) {
                conversations.remove(at: indexToRemove)
                
                reference.setValue(conversations)
            }
        }
    }
    
    
}
