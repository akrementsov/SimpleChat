//
//  AuthManager.swift
//  SimpleChat
//
//  Created by Andrey on 10/11/22.
//

import Foundation
import Firebase

protocol AuthManagerDelegate: AnyObject {
    func didReceiveError(_ authManager: AuthManager, error: Error)
    func didAuthSuccessfully(_ authManager: AuthManager, authResult: AuthDataResult)
    func didAuthWithoutVerification(_ authManager: AuthManager, authResult: AuthDataResult)
    func didSendResetPassword(_ authManager: AuthManager)
    func didCreateUser(_ authManager: AuthManager, authResult: AuthDataResult)
    func changeInfoSuccessfully(_ authManager: AuthManager)
}

extension AuthManagerDelegate {
    func didReceiveError(_ authManager: AuthManager, error: Error) {}
    func didAuthSuccessfully(_ authManager: AuthManager, authResult: AuthDataResult) {}
    func didAuthWithoutVerification(_ authManager: AuthManager, authResult: AuthDataResult) {}
    func didSendResetPassword(_ authManager: AuthManager) {}
    func didCreateUser(_ authManager: AuthManager, authResult: AuthDataResult) {}
    func changeInfoSuccessfully(_ authManager: AuthManager) {}
}

final class AuthManager {
    weak var delegate: AuthManagerDelegate?
    
    // sign in function
    func signInWith(email: String, password: String) {
        let email = email
        let password = password
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            switch error {
            case .some(let error):
                self.delegate?.didReceiveError(self, error: error)
                
            case .none:
                guard let result = authResult else { return }
                // if user exist and verified send data to delegate
                if result.user.isEmailVerified {
                    self.delegate?.didAuthSuccessfully(self, authResult: result)
                } else {
                    // if not verified send message to verify
                    self.delegate?.didAuthWithoutVerification(self, authResult: result)
                }
            }
        }
    }
    
    func logOut() {
        do {
            try Auth.auth().signOut()
        } catch {

        }
    }
    // reset password function
    func resetPassword(_ email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            switch error {
            case .some(let error):
                self.delegate?.didReceiveError(self, error: error)
            case .none:
                self.delegate?.didSendResetPassword(self)
            }
        }
    }
    
    // creating function
    func createUser(email: String, password: String, name: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            switch error {
            case .some(let error):
                self.delegate?.didReceiveError(self, error: error)
            case .none:
                guard let result = authResult else { return }
                
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = name
                changeRequest?.commitChanges()
                
                self.delegate?.didCreateUser(self, authResult: result)
                
                result.user.sendEmailVerification()
                
                self.logOut()
            }
        }
    }
    
    // check authentication data
    func reAuth(_ oldPassword: String) {
        let currentUser = Auth.auth().currentUser
        
        guard let email = currentUser?.email else { return }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        
        currentUser?.reauthenticate(with: credential) { authResult, error in
            switch error {
            case .some(let error):
                self.delegate?.didReceiveError(self, error: error)
            case .none:
                guard let result = authResult else { return }
                self.delegate?.didAuthSuccessfully(self, authResult: result)
            }
        }
    }
    
    func updatePassword(_ newPassword: String) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            switch error {
            case .some(let error): self.delegate?.didReceiveError(self, error: error)
            case .none:
                self.delegate?.changeInfoSuccessfully(self)
            }
        }
    }
    
    func updateName(_ newName: String) {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = newName
        changeRequest?.commitChanges() { error in
            switch error {
            case .some(let error): self.delegate?.didReceiveError(self, error: error)
            case .none:
                self.delegate?.changeInfoSuccessfully(self)
            }
        }
    }
}
