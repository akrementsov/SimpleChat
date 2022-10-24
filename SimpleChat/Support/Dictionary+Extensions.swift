//
//  Dictionary+Extensions.swift
//  SimpleChat
//
//  Created by Andrey on 10/13/22.
//

import Foundation
import Firebase

extension Dictionary where Key == String {
    func asMessageModel() -> MessageModel? {
        guard let name = self[K.Database.nameField] as? String,
              let date = self[K.Database.dateField] as? Timestamp,
              let userUID = self[K.Database.uuidField] as? String,
              let message = self[K.Database.messageField] as? String else { return nil }
        
        return MessageModel(userUID: userUID, userName: name, message: message, date: date)
    }
}
