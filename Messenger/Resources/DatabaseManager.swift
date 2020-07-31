//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 23/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import Foundation
import FirebaseDatabase

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
    
    public func getAllUsers(completion: @escaping (Result<[Dictionary<String, [String : String]>.Element],Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: [String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let users = value.sorted { (lhs, rhs) -> Bool in
                let lhsFirstName = lhs.value["first_name"]!
                let rhsFirstName = rhs.value["first_name"]!
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
        reference.observeSingleEvent(of: .value) { (snapshot) in
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
    
    public func getAllConversations(forUserID userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    public func getAllMessages(forConversationID conversationID: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    public func sendMessage(_ message: Message, toConversationID: String, completion: @escaping (Bool) -> Void) {
        
    }
    
    
}
