//
//  MessengerUser.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 23/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

struct MessengerUser: Encodable {
    var firstName: String
    var lastName: String
    var emailAddress: String
    
    enum CodingKeys: String, CodingKey {
        case firstName, lastName
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
    }
}
