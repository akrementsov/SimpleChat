//
//  ViewController.swift
//  SimpleChat
//
//  Created by Andrey on 9/30/22.
//

import UIKit
import Firebase

final class ResetViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var constraint: NSLayoutConstraint!
    @IBOutlet weak var resetPasswordButton: UIButton!
    @IBOutlet weak var waitingScreen: UIView!
    
    private let authManager = AuthManager()
    
    lazy private var badInternetAlert: UIAlertController = {
        let alert = UIAlertController(title: "Bad internet connection", message: nil, preferredStyle: .alert)
        let button = UIAlertAction(title: "Ok", style: .cancel)
        alert.addAction(button)
        return alert
    }()
    
    lazy private var resetPasswordAlert: UIAlertController = {
        let alert = UIAlertController(title: "Reset password email was sent", message: nil, preferredStyle: .alert)
        let button = UIAlertAction(title: "Ok", style: .cancel) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addAction(button)
        return alert
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.addKeyboardListener()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    @IBAction func resetButtonPressed(_ sender: UIButton) {
        self.resetPassword()
    }
    
}

// MARK: - Functions
extension ResetViewController {
    private func configure() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        self.emailTextField.delegate = self
        self.emailTextField.resetShadow()
        self.emailTextField.layer.cornerCurve = .continuous
        
        self.resetPasswordButton.layer.cornerCurve = .continuous
        self.resetPasswordButton.isEnabled = false
        self.resetPasswordButton.backgroundColor = K.Colors.lightGreen
        
        self.authManager.delegate = self
        
        self.waitingScreen.alpha = 0
    }
    
    private func waiting() {
        var alpha: CGFloat = 0
        
        if self.waitingScreen.alpha > 0 {
            alpha = 0
        } else {
            alpha = 0.6
        }
        UIView.animate(withDuration: K.Animation.verificationDuration) {
            self.waitingScreen.alpha = alpha
        }
    }
    
    private func resetPassword() {
        guard let email = self.emailTextField.text else { return }
        self.emailTextField.resetShadow()
        self.authManager.resetPassword(email)
        self.view.endEditing(true)
        self.waiting()
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
            let bottomPoint = self.resetPasswordButton.frame.origin.y + self.resetPasswordButton.frame.height
            let keyboardTopPoint = keyboardEndFrame.origin.y
            let difference = keyboardTopPoint - bottomPoint
            
            if difference < 0 {
                self.constraint.constant = self.constraint.constant + difference - 10
                
                UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: [UIView.AnimationOptions(rawValue: curve)]) {
                    self.view.layoutIfNeeded()
                }
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

// MARK: - Firebase Auth
extension ResetViewController: AuthManagerDelegate {
    
    func didSendResetPassword(_ authManager: AuthManager) {
        self.waiting()
        self.present(self.resetPasswordAlert, animated: true)
        self.emailTextField.text = ""
    }
    
    func didReceiveError(_ authManager: AuthManager, error: Error) {
        self.waiting()
        let error = error as NSError
        let errorAuthCode = AuthErrorCode(_nsError: error)
        let errorCode = errorAuthCode.code
        
        switch errorCode {
        case .invalidEmail:
            self.emailTextField.shake()
        case .userNotFound:
            self.emailTextField.shake()
        case .networkError:
            self.present(self.badInternetAlert, animated: true)
        default: print(error)
        }
    }
}

// MARK: - UITextFieldDelegate
extension ResetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.resetShadow()
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text else { return }
        
        if !text.isEmailCorrect() {
            textField.becomeRed()
            self.resetPasswordButton.isEnabled = false
            self.resetPasswordButton.backgroundColor = K.Colors.lightGreen
        } else {
            self.resetPasswordButton.isEnabled = true
            self.resetPasswordButton.backgroundColor = K.Colors.green
            textField.becomeGreen()
        }
    }
}

