//
//  String+.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 23/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

extension String {
    
    /// replace '.' '#' '$' '[' and ']' with '-' because `DatabaseReference.child(_:)` doesn't allow them.
    func safeForDatabaseReferenceChild() -> String {
        var safeEmail = self
        let unwantedCharacters = [".", "#", "$", "[", "]"]
        for character in unwantedCharacters {
            safeEmail = safeEmail.replacingOccurrences(of: character, with: "-")
        }
        return safeEmail
    }
    
    
}

