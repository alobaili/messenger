//
//  MessengerUser.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 23/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

struct MessengerUser: Codable {
    var id: String
    var firstName: String?
    var lastName: String?
    var conversations: [Conversation]?
    
    var profileImageFileName: String {
        "\(id.safeForDatabaseReferenceChild())_profile_image.png"
    }
    
    enum CodingKeys: CodingKey {
        case firstName, lastName, conversations
    }
    
    init(id: String, firstName: String?, lastName: String?, conversations: [Conversation]?) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.conversations = conversations
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        conversations = try container.decode([Conversation].self, forKey: .conversations)
        
        id = container.codingPath.first!.stringValue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(conversations, forKey: .conversations)
    }
}

/// This type is used to decode the values of dynamic keys in a JSON object.
///
/// Consider the following JSON data:
/// ```
/// {
///     "user1": {
///         "first_name": "Max",
///         "last_name": "Pain"
///     },
///     "user2": {
///         "first_name": "John",
///         "last_name": "Smith"
///     }
/// }
/// ```
/// The above code have two different keys, each of which contains an object with the same structure.
///
/// The special implementation of `MessengerUserArray`'s `init(from:)` loops through each key and decodes its object as a `MessengerUser`. Inside `init(from:)` of `MessengerUser`, the `id` is initialized using the first `CodingKey` in the container's `codingPath` array, which is the user's ID. This flattens the JSON to a Swift structure suitable to use in the project for things like populating a table view.
struct MessengerUserArray: Decodable {
    var messengerUsers: [MessengerUser]

    // Define DynamicCodingKeys type needed for creating
    // decoding container from JSONDecoder
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        // Not interested in `Int` keys for now.
        var intValue: Int?
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        var temporaryArray = [MessengerUser]()

        for key in container.allKeys {
            let messengerUser = try container.decode(MessengerUser.self, forKey: DynamicCodingKeys(stringValue: key.stringValue)!)
            temporaryArray.append(messengerUser)
        }

        messengerUsers = temporaryArray
    }
}
