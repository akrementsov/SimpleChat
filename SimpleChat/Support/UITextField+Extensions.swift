//
//  UITextField+Extensions.swift
//  SimpleChat
//
//  Created by Andrey on 10/6/22.
//

import Foundation
import UIKit

extension UITextField {
    func showPasswordButton() {
        let button = UIButton(type: .custom)
        let imageNormal = UIImage(systemName: "eye")
        button.tintColor = K.Colors.middleGreen
        button.setImage(imageNormal, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: self.frame.height, height : self.frame.height)
        
        self.rightView = UIView(frame: CGRect(x: self.frame.size.width - 25, y: 0, width: button.frame.width + 5, height: button.frame.height))
        self.rightView?.addSubview(button)
        self.rightViewMode = .always
        
        button.addTarget(self, action: #selector(self.changeSecure(_:)), for: .touchUpInside)
    }
    
    @IBAction func changeSecure(_ sender: UIButton) {
        self.isSecureTextEntry.toggle()
        var image: UIImage?
        if self.isSecureTextEntry {
            image = UIImage(systemName: "eye")
        } else {
            image = UIImage(systemName: "eye.slash")
        }
        
        sender.setImage(image, for: .normal)
    }
    
    func becomeGreen() {
        UIView.animate(withDuration: K.Animation.verificationDuration, delay: 0) {
            self.layer.shadowColor = UIColor.systemGreen.cgColor
            self.layer.shadowOpacity = 1
        }
    }
    
    func becomeRed() {
        UIView.animate(withDuration: K.Animation.verificationDuration, delay: 0) {
            self.layer.shadowColor = UIColor.systemRed.cgColor
            self.layer.shadowOpacity = 1
        }
    }
    
    func becomeYellow() {
        UIView.animate(withDuration: K.Animation.verificationDuration, delay: 0) {
            self.layer.shadowColor = UIColor.systemYellow.cgColor
            self.layer.shadowOpacity = 1
        }
    }
    
    func resetShadow() {
        UIView.animate(withDuration: K.Animation.verificationDuration, delay: 0) {
            self.layer.shadowOffset = CGSize(width: 0, height: 1.5)
            self.layer.shadowRadius = 0
            self.layer.shadowOpacity = 0
        }
    }
    
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = K.Animation.verificationDuration
        animation.values = [0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        self.layer.add(animation, forKey: "shake")
        
        self.becomeRed()
    }
}
