//
//  MessageModel.swift
//  SimpleChat
//
//  Created by Andrey on 10/13/22.
//

import Foundation
import Firebase

struct MessageModel {
    let userUID: String
    let userName: String
    let message: String
    let date: Timestamp
}

extension MessageModel {
    func convertToDictionary() -> [String: Any] {
        var dictionary = [String: Any]()
        
        dictionary[K.Database.uuidField] = self.userUID
        dictionary[K.Database.nameField] = self.userName
        dictionary[K.Database.messageField] = self.message
        dictionary[K.Database.dateField] = self.date
        
        return dictionary
    }
}
