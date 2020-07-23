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
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    let encoder = JSONEncoder()
    
    
    private init() {
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    
}

// MARK: - Account Management

extension DatabaseManager {
    
    public func insertUser(_ user: MessengerUser) {
        do {
            let userData = try encoder.encode(user)
            let userDictionary = try JSONSerialization.jsonObject(with: userData, options: .allowFragments) as! [String: Any]
            database.child(user.emailAddress.safeForDatabaseReferenceChild()).setValue(userDictionary)
        } catch {
            fatalError("\(error)")
        }
    }
    
    public func userExists(withEmail email: String, completion: @escaping (Bool) -> Void) {
        database.child(email.safeForDatabaseReferenceChild()).observeSingleEvent(of: .value) { (snapshot) in
            completion((snapshot.value as? String) != nil)
        }
    }
    
    
}
