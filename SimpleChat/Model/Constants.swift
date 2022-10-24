//
//  File.swift
//  SimpleChat
//
//  Created by Andrey on 10/1/22.
//

import Foundation
import UIKit

struct K {
    // MARK: - some chat settings
    static let myCellIdentifier = "myCell"
    static let thereCellIdentifier = "thereCell"
    static let cellNibName = "MessageCellView"
    static let logo = UIImage(named: "logo")
    
    // MARK: - database fieldes
    struct Database {
        static let collectionName = "chat"
        static let nameField = "userName"
        static let messageField = "messageBody"
        static let uuidField = "userUID"
        static let dateField = "date"
    }
    
    struct Colors{
        static let bg = UIColor(named: "BGColor")
        static let orange = UIColor(named: "OrangeColor")
        static let lightOrange = UIColor(named: "LightOrangeColor")
        static let green = UIColor(named: "GreenColor")
        static let middleGreen = UIColor(named: "MiddleGreenColor")
        static let lightGreen = UIColor(named: "LightGreenColor")
        static let superLightGreen = UIColor(named: "SuperLightGreenColor")
    }
    // MARK: - settings for bottom bar
    struct BottomBarViewSettings {
        static let fontSize: CGFloat = 17
        static let buttonImage = "paperplane.fill"
        static let lines: CGFloat = 6
        
        static var textViewHeight: CGFloat { fontSize + 20 }
        static var maxHeight: CGFloat { (fontSize * (lines + 1) + 20) }
    }
    // MARK: - some animation duration
    struct Animation {
        static let verificationDuration: CGFloat = 0.25
        static let textViewDidChangeDuration: CGFloat = 0.08
    }
    // MARK: - hint about password requirements
    struct Texts {
        static let passwordHint =
        """
        ☑ at least one uppercase
        ☑ at least one digit
        ☑ at least one lowercase
        ☑ at least one symbol
        ☑ min 8 characters total
        """
    }
}
