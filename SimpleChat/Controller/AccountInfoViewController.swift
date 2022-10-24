//
//  AccountInfoViewController.swift
//  SimpleChat
//
//  Created by Andrey on 10/21/22.
//

import UIKit
import Firebase

class AccountInfoViewController: UIViewController {
    @IBOutlet weak var constraint: NSLayoutConstraint!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var waitingScreen: UIView!
    @IBOutlet weak var changeAccountButton: UIButton!
    
    @IBOutlet var textFields: [UITextField]!
    
    private var verified: [Bool?] = [nil, nil, nil]
    private var oldPasswordChecked = false
    private let authManager = AuthManager()
    private var canShowSuccesses = false
    
    lazy private var passwordTip: PasswordTipView = {
        let tip = PasswordTipView()
        tip.alpha = 0
        tip.translatesAutoresizingMaskIntoConstraints = false
        return tip
    }()
    
    lazy private var badInternetAlert: UIAlertController = {
        let alert = UIAlertController(title: "Bad internet connection", message: nil, preferredStyle: .alert)
        let button = UIAlertAction(title: "Ok", style: .cancel)
        alert.addAction(button)
        return alert
    }()
    
    lazy private var changeAlert: UIAlertController = {
        let alert = UIAlertController(title: "Successes", message: "Change your account info successfully", preferredStyle: .alert)
        
        let sendButton = UIAlertAction(title: "Ok", style: .default) { _ in
            self.dismiss(animated: true)
        }
        
        alert.addAction(sendButton)
        return alert
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configure()
        self.addKeyboardListener()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if touches.first?.view == self.passwordTip {
            self.showHideInfo()
        } else {
            self.view.endEditing(true)
        }
    }
    
    @IBAction func changeAccountButtonPressed(_ sender: UIButton) {
        guard let text = self.textFields[3].text?.trimSpacesAndNewLines() else { return }
        self.authManager.reAuth(text)
        self.canShowSuccesses = true
        self.view.endEditing(true)
        self.isWaiting(true)
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        self.showHideInfo()
    }
}

extension AccountInfoViewController {
    private func configure() {
        self.textFields.forEach {
            $0.delegate = self
            $0.layer.masksToBounds = false
            $0.layer.cornerCurve = .continuous
            $0.resetShadow()
            
            if $0.tag > 0 {
                $0.showPasswordButton()
            }
        }
        
        self.authManager.delegate = self
        
        self.changeAccountButton.layer.cornerCurve = .continuous
        self.changeAccountButton.isEnabled = false
        self.changeAccountButton.backgroundColor = K.Colors.lightGreen
        self.waitingScreen.alpha = 0
        
        self.configureInfo()
    }
    
    private func configureInfo() {
        self.view.addSubview(self.passwordTip)
        
        self.passwordTip.widthAnchor.constraint(equalToConstant: 180).isActive = true
        self.passwordTip.heightAnchor.constraint(equalToConstant: 110).isActive = true
        self.passwordTip.bottomAnchor.constraint(equalTo: self.infoButton.topAnchor, constant: -2).isActive = true
        self.passwordTip.trailingAnchor.constraint(equalTo: self.infoButton.centerXAnchor, constant: +18).isActive = true
    }
    
    private func checkTextFields(_ textField: UITextField) {
        guard let text = textField.text?.trimSpacesAndNewLines() else { return }
        
        switch textField.tag {
        case 0:
            if !text.isEmpty {
                textField.becomeGreen()
                self.verified[0] = true
            } else {
                textField.resetShadow()
                self.verified[0] = nil
            }
        case 1:
            if text.isPasswordCorrect() {
                textField.becomeGreen()
                self.verified[1] = true
            } else if text.isEmpty {
                textField.resetShadow()
                self.verified[1] = nil
            } else {
                textField.becomeRed()
                self.verified[1] = false
            }
        case 2:
            if text == self.textFields[1].text && text.isPasswordCorrect() {
                textField.becomeGreen()
                self.verified[2] = true
            } else if text.isEmpty {
                textField.resetShadow()
                self.verified[2] = nil
            } else {
                textField.resetShadow()
                self.verified[2] = false
            }
        case 3:
            textField.resetShadow()
            if !text.isEmpty {
                self.oldPasswordChecked = true
            } else {
                self.oldPasswordChecked = false
            }
        default: break
        }
        
        if !self.verified.contains(false) && self.verified.contains(true) && self.oldPasswordChecked{
            self.changeAccountButton.isEnabled = true
            self.changeAccountButton.backgroundColor = K.Colors.green
        } else {
            self.changeAccountButton.isEnabled = false
            self.changeAccountButton.backgroundColor = K.Colors.lightGreen
        }
    }
    
    private func isWaiting(_ status: Bool) {
        var alpha: CGFloat = 0
        
        if !status {
            alpha = 0
        } else {
            alpha = 0.6
        }
        UIView.animate(withDuration: K.Animation.verificationDuration) {
            self.waitingScreen.alpha = alpha
        }
    }
    
    private func showHideInfo() {
        UIView.animate(withDuration: K.Animation.verificationDuration) {
            if self.passwordTip.alpha == 1 {
                self.passwordTip.alpha = 0
            } else {
                self.passwordTip.alpha = 1
            }
        }
    }
    
    private func addKeyboardListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ sender: Notification) {
        guard let curve = sender.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              let duration = sender.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let keyboardEndFrame = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let keyboardBeginFrame = sender.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect else { return }
        
        if keyboardEndFrame.origin.y < keyboardBeginFrame.origin.y {
            let bottomPoint = self.changeAccountButton.frame.origin.y + self.changeAccountButton.frame.height
            let keyboardTopPoint = keyboardEndFrame.origin.y
            let difference = keyboardTopPoint - bottomPoint
            
            self.constraint.constant = self.constraint.constant - difference - 20
            
            UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: [UIView.AnimationOptions(rawValue: curve)]) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc private func keyboardWillHide(_ sender: Notification) {
        guard let curve = sender.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              let duration = sender.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let keyboardEndFrame = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let keyboardBeginFrame = sender.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect else { return }
        
        if keyboardEndFrame.origin.y > keyboardBeginFrame.origin.y {
            self.constraint.constant = 0
            
            UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: [UIView.AnimationOptions(rawValue: curve)]) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

extension AccountInfoViewController: AuthManagerDelegate {
    func didReceiveError(_ authManager: AuthManager, error: Error) {
        self.isWaiting(false)
        let error = error as NSError
        let errorAuthCode = AuthErrorCode(_nsError: error)
        let errorCode = errorAuthCode.code
        
        switch errorCode {
        case .networkError:
            self.present(badInternetAlert, animated: true)
        case .wrongPassword:
            self.textFields[3].becomeRed()
            self.textFields[3].shake()
        default: break
        }
    }
    
    func didAuthSuccessfully(_ authManager: AuthManager, authResult: AuthDataResult) {
        if self.verified[1] != nil, let password = textFields[1].text?.trimSpacesAndNewLines() {
            self.authManager.updatePassword(password)
        }
        
        if self.verified[0] != nil, let name = textFields[0].text?.trimSpacesAndNewLines() {
            self.authManager.updateName(name)
        }
    }
    
    func changeInfoSuccessfully(_ authManager: AuthManager) {
        if self.canShowSuccesses {
            self.canShowSuccesses = false
            self.textFields.forEach {
                $0.resetShadow()
                $0.text = ""
            }
            self.isWaiting(false)
            self.present(self.changeAlert, animated: true)
        }
    }
}

extension AccountInfoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 3 {
            self.view.endEditing(true)
        } else {
            self.textFields[textField.tag + 1].becomeFirstResponder()
        }
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        self.checkTextFields(textField)
    }
}
