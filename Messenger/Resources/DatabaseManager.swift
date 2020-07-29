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
