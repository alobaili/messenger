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
import CoreLocation

/// A manager object for communicating with Firebase's Realtime Database.
final class DatabaseManager {
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
    /// The singleton object for this class.
    public static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    private let iso8601DateFormatter = ISO8601DateFormatter()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    
    private init() {
        encoder.keyEncodingStrategy = .convertToSnakeCase
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    
}

// MARK: - Account Management

extension DatabaseManager {
    
    /// Inserts a user into the database.
    /// - Parameters:
    ///   - user: The user to insert.
    ///   - completion: Completes with `true` if the insertion is successful. Otherwise, complete's with `false`.
    public func insertUser(_ user: MessengerUser, completion: @escaping (Bool) -> Void) {
        do {
            let userData = try encoder.encode(user)
            let userDictionary = try JSONSerialization.jsonObject(with: userData, options: .allowFragments) as! [String: Any]
            database.child("users").child(user.id.safeForDatabaseReferenceChild()).setValue(userDictionary) { (error, _) in
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
    
    /// Checks the database if a user with the specified `id` exists.
    /// - Parameters:
    ///   - id: The user ID to check for.
    ///   - completion: Completes with `true` if the user exists. Otherwise, completes with `false`.
    public func userExists(withID id: String, completion: @escaping (Bool) -> Void) {
        database.child("users").child(id.safeForDatabaseReferenceChild()).observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot.exists())
        }
    }
    
    /// Fetches the list of all users in the database.
    /// - Parameter completion: Completes with a successful `Result` containing the array of `MessengerUser` objects. Otherwise, completes with a failed `Result` containing the error.
    public func getAllUsers(completion: @escaping (Result<[MessengerUser], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self, let value = snapshot.value as? [String: [String: Any]] else {
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
    
    /// Fetches from the database a conversation in the recipient's conversations where the other party is the currently signed in user.
    /// - Parameters:
    ///   - recipientID: The user ID of the recipient.
    ///   - completion: Completes with the conversation ID if the conversation exists. Otherwise, completes with `nil`.
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
    
    /// creates a new conversation in the database between the currently signed in user and another user.
    /// - Parameters:
    ///   - userID: The recipient user's ID.
    ///   - name: The recipient user's name.
    ///   - firstMessage: The first message to associate with the new conversation.
    ///   - completion: Completes with `true` if the conversation is created successfully. Otherwise, completes with `false`.
    public func createNewConversation(withUserID userID: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentUserID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID) else {
            return
        }
        
        let safeCurrentUserID = currentUserID.safeForDatabaseReferenceChild()
        
        let reference = database.child("users").child(safeCurrentUserID)
        
        reference.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self, snapshot.exists(), var user = snapshot.value as? [String: Any] else {
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
                .observeSingleEvent(of: .value) { [weak self] (snapshot) in
                    guard let self = self else { return }
                    
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
            
            reference.setValue(user) { (error, _) in
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
    
    /// Fetches the database for the list of all conversations for the specifies user ID.
    ///
    /// This function reactively monitor's the conversations for the specified user and calls `completion` whenever there is a change (insertion, update, or deletion).
    /// - Parameters:
    ///   - userID: The ID of the user owning the requested conversations.
    ///   - completion: Completes with an array of `Conversation` objects. If there are no conversations, completes with an empty array.
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
    
    /// Fetched the database for all messages belonging to the specified conversation ID.
    ///
    /// This function reactively monitor's the messages for the specified conversation and calls `completion` whenever there's a change (insertion, update, or deletion).
    /// - Parameters:
    ///   - conversationID: The ID of the conversation owning the requested messages.
    ///   - completion: Completes with a successful `Result` containing an array of `Message` objects. If there are no messages, completes with a failed `Result` containing an `Error`.
    public func getAllMessages(forConversationID conversationID: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(conversationID.safeForDatabaseReferenceChild())/messages").observe(.value) { [weak self] (snapshot) in
            guard let self = self, let value = snapshot.value as? [[String: Any]] else {
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
                    case "text":
                        kind = .text(content)
                    
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
                    
                    case "location":
                        let coordinateComponents = content.components(separatedBy: ",")
                        guard
                            let latitude = CLLocationDegrees(coordinateComponents[0]),
                            let longitude = CLLocationDegrees(coordinateComponents[1])
                            else {
                                return nil
                        }
                        
                        let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                                size: CGSize(width: 300, height: 150))
                        
                        kind = .location(location)
                    
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
    
    /// Sends a message to the specified recipient user ID and conversation ID.
    /// - Parameters:
    ///   - message: The message to send.
    ///   - recipientID: The recipient user ID who should receive the message.
    ///   - conversationID: The conversation ID owning the message.
    ///   - name: Name of the user associated with this message.
    ///   - completion: Completes with `true` if the message was successfully sent. Otherwise, completes with `false`.
    public func sendMessage(_ message: Message, recipientID: String, conversationID: String, name: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID) else {
            completion(false)
            return
        }
        
        // Add the new message to the messages array of the passed conversation ID
        database.child("\(conversationID.safeForDatabaseReferenceChild())/messages").observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self, var currentMessages = snapshot.value as? [[String: Any]] else {
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
                case .location(let locationItem):
                    let location = locationItem.location
                    content = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
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
                "name": Auth.auth().currentUser!.displayName!
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
    
    /// Deletes the specified conversation for the currently signed in user from the database.
    /// - Parameter conversation: The conversation to delete.
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
