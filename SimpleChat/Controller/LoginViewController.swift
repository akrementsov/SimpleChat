//
//  ViewController.swift
//  SimpleChat
//
//  Created by Andrey on 9/30/22.
//

import UIKit
import Firebase

final class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var constraint: NSLayoutConstraint!
    @IBOutlet weak var signupStack: UIStackView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var waitingScreen: UIView!
    
    private let authManager = AuthManager()
    private var verified = [Bool](repeating: false, count: 2)
    
    lazy private var verificationAlert: UIAlertController = {
        let alert = UIAlertController(title: "Your email isn't verified", message: "Should we send you verification email?", preferredStyle: .alert)
        
        let noButton = UIAlertAction(title: "No", style: .cancel)
        let sendButton = UIAlertAction(title: "Send", style: .default) { _ in
            Auth.auth().currentUser?.sendEmailVerification()
            self.emailTextField.resetShadow()
        }
        alert.addAction(noButton)
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
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        self.login()
    }
    
    @IBAction func signupButtonPressed(_ sender: UIButton) {
        self.view.endEditing(true)
        self.performSegue(withIdentifier: "signupSegue", sender: self)
    }
    
    @IBAction func forgotPasswordPressed(_ sender: UIButton) {
        self.view.endEditing(true)
        self.performSegue(withIdentifier: "resetPasswordSegue", sender: nil)
    }
    
}

// MARK: - Functions
extension LoginViewController {
    private func configure() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        self.emailTextField.delegate = self
        self.emailTextField.resetShadow()
        self.emailTextField.layer.cornerCurve = .continuous
        self.passwordTextField.delegate = self
        self.passwordTextField.resetShadow()
        self.passwordTextField.showPasswordButton()
        self.passwordTextField.layer.cornerCurve = .continuous
        
        self.loginButton.layer.cornerCurve = .continuous
        
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
    
    private func login() {
        self.view.endEditing(true)
        guard let email = self.emailTextField.text,
              let password = self.passwordTextField.text else { return }
        self.authManager.signInWith(email: email, password: password)
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
            let bottomPoint = self.loginButton.frame.origin.y + self.loginButton.frame.height
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
extension LoginViewController: AuthManagerDelegate {
    func didAuthWithoutVerification(_ authManager: AuthManager, authResult: AuthDataResult) {
        self.waiting()
        self.present(self.verificationAlert, animated: true)
    }
    
    func didAuthSuccessfully(_ authManager: AuthManager, authResult: AuthDataResult) {
        self.waiting()
        self.performSegue(withIdentifier: "chatSegue", sender: self)
        self.view.endEditing(true)
    }
    
    func didReceiveError(_ authManager: AuthManager, error: Error) {
        self.waiting()
        let error = error as NSError
        let errorAuthCode = AuthErrorCode(_nsError: error)
        let errorCode = errorAuthCode.code
        
        switch errorCode {
        case .userNotFound:
            self.emailTextField.shake()
            self.passwordTextField.text = ""
        case .networkError:
            self.present(badInternetAlert, animated: true)
        case .wrongPassword:
            self.passwordTextField.shake()
        default: break
        }
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 0 {
            self.passwordTextField.becomeFirstResponder()
        } else if textField.tag == 1 {
            self.view.endEditing(true)
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.resetShadow()
    }
}

