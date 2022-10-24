//
//  String+Extension.swift
//  SimpleChat
//
//  Created by Andrey on 10/6/22.
//

import Foundation
import UIKit

extension String {
    func isPasswordCorrect() -> Bool {
        // least one uppercase
        // least one digit
        // least one lowercase
        // least one symbol
        // min 8 characters total
        let passwordRegx = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&<>*~:`-]).{8,}$"
        let passwordCheck = NSPredicate(format: "SELF MATCHES %@", passwordRegx)
        return passwordCheck.evaluate(with: self)
    }
    
    func getMissingValidation() -> [Bool] {
        var errors = [Bool](repeating: false, count: 5)
        
        if(!NSPredicate(format:"SELF MATCHES %@", ".*[A-Z]+.*").evaluate(with: self)) {
            errors[0] = true
        }
        
        if(!NSPredicate(format:"SELF MATCHES %@", ".*[0-9]+.*").evaluate(with: self)) {
            errors[1] = true
        }

        if(!NSPredicate(format:"SELF MATCHES %@", ".*[!&^%$#@()/]+.*").evaluate(with: self)) {
            errors[2] = true
        }
        
        if(!NSPredicate(format:"SELF MATCHES %@", ".*[a-z]+.*").evaluate(with: self)) {
            errors[3] = true
        }
        
        if(self.count < 8){
            errors[4] = true
        }
        return errors
    }
    
    func isEmailCorrect() -> Bool {
        let firstPart = "[A-Z0-9a-z]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
        let serverPart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
        let emailRegex = firstPart + "@" + serverPart + "[A-Za-z]{2,8}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return emailPredicate.evaluate(with: self)
    }
    
    func trimSpacesAndNewLines() -> String {
        let newString = self.trimmingCharacters(in: .whitespacesAndNewlines).reduce(into: "") {
            if $0.suffix(2) == "\n\n", $0.last == $1 {
                $0.append("")
            } else {
                $0.append($1)
            }
        }
        return newString
    }
}
