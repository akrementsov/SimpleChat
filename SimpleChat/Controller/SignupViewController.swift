//
//  SignupViewController.swift
//  SimpleChat
//
//  Created by Andrey on 10/1/22.
//

import UIKit
import Firebase

final class SignupViewController: UIViewController {
    
    @IBOutlet var textFields: [UITextField]!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var constraint: NSLayoutConstraint!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var waitingScreen: UIView!
    
    private var verified = [Bool](repeating: false, count: 4)
    private let authManager = AuthManager()
    
    lazy private var passwordTip: PasswordTipView = {
        let tip = PasswordTipView()
        tip.alpha = 0
        tip.translatesAutoresizingMaskIntoConstraints = false
        return tip
    }()

    lazy private var checkEmailAlert: UIAlertController = {
        let alert = UIAlertController(title: "Check your email", message: "We sent you verification message", preferredStyle: .alert)
        
        let sendButton = UIAlertAction(title: "Ok", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        alert.addAction(sendButton)
        return alert
    }()
    
    lazy private var badInternetAlert: UIAlertController = {
        let alert = UIAlertController(title: "Bad internet connection", message: nil, preferredStyle: .alert)
        let button = UIAlertAction(title: "Ok", style: .cancel)
        alert.addAction(button)
        return alert
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    @IBAction func createAccountButtonPressed(_ sender: UIButton) {
        guard let email = textFields[1].text,
              let password = textFields[2].text,
              let name = textFields[0].text else { return }
        self.authManager.createUser(email: email, password: password, name: name)
        self.isWaiting(true)
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        self.showHideInfo()
    }
}

// MARK: - Functions
extension SignupViewController {
    private func configure() {
        self.textFields.forEach {
            $0.delegate = self
            $0.layer.masksToBounds = false
            $0.layer.cornerCurve = .continuous
            $0.resetShadow()
            
            if $0.tag > 1 {
                $0.showPasswordButton()
            }
        }
        
        self.authManager.delegate = self
        
        self.createAccountButton.layer.cornerCurve = .continuous
        self.createAccountButton.isEnabled = false
        self.createAccountButton.backgroundColor = K.Colors.lightGreen
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
    
    private func checkTextFields(_ textField: UITextField) {
        guard let text = textField.text?.trimSpacesAndNewLines() else { return }
        
        switch textField.tag {
        case 0:
            if !text.isEmpty {
                textField.becomeGreen()
                self.verified[0] = true
            } else {
                textField.becomeRed()
                self.verified[0] = false
            }
        case 1:
            if text.isEmailCorrect() {
                textField.becomeGreen()
                self.verified[1] = true
            } else {
                textField.becomeRed()
                self.verified[1] = false
            }
        case 2:
            if text.isPasswordCorrect() {
                textField.becomeGreen()
                self.verified[2] = true
            } else {
                textField.becomeRed()
                self.verified[2] = false
            }
        case 3:
            if text == self.textFields[2].text && text.isPasswordCorrect() {
                textField.becomeGreen()
                self.verified[3] = true
            } else {
                textField.becomeRed()
                self.verified[3] = false
            }
        default: break
        }
        
        if !verified.contains(false) {
            self.createAccountButton.isEnabled = true
            self.createAccountButton.backgroundColor = K.Colors.green
        } else {
            self.createAccountButton.isEnabled = false
            self.createAccountButton.backgroundColor = K.Colors.lightGreen
        }
    }
    
    @objc private func keyboardWillShow(_ sender: Notification) {
        guard let curve = sender.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              let duration = sender.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let keyboardEndFrame = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let keyboardBeginFrame = sender.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect else { return }
        
        if keyboardEndFrame.origin.y < keyboardBeginFrame.origin.y {
            let bottomPoint = self.createAccountButton.frame.origin.y + self.createAccountButton.frame.height
            let keyboardTopPoint = keyboardEndFrame.origin.y
            let difference = keyboardTopPoint - bottomPoint
            
            self.constraint.constant = self.constraint.constant + difference - 10
            
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

// MARK: - AuthManagerDelegate
extension SignupViewController: AuthManagerDelegate {
    func didReceiveError(_ authManager: AuthManager, error: Error) {
        self.isWaiting(false)
        let error = error as NSError
        let errorAuthCode = AuthErrorCode(_nsError: error)
        let errorCode = errorAuthCode.code
        
        switch errorCode {
        case .emailAlreadyInUse:
            self.textFields[1].shake()
        case .networkError:
            self.present(badInternetAlert, animated: true)
        default: break
        }
    }
    
    func didCreateUser(_ authManager: AuthManager, authResult: AuthDataResult) {
        self.isWaiting(false)
        self.present(self.checkEmailAlert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension SignupViewController: UITextFieldDelegate {
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
