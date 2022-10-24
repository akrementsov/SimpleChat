//
//  DatabaseManager.swift
//  SimpleChat
//
//  Created by Andrey on 10/13/22.
//

import Foundation
import Firebase

protocol DatabaseManagerDelegate {
    func didReceiveMessages(_ databaseManager: DatabaseManager, messages: [MessageModel])
    func listenerDidReceiveMessages(_ databaseManager: DatabaseManager, messages: [MessageModel])
    func didReceiveError(_ databaseManager: DatabaseManager, error: Error)
}

extension DatabaseManagerDelegate {
    func didReceiveMessages(_ databaseManager: DatabaseManager, messages: [MessageModel]) {}
    func didReceiveError(_ databaseManager: DatabaseManager, error: Error) {}
    func listenerDidReceiveMessages(_ databaseManager: DatabaseManager, messages: [MessageModel]) {}
}

final class DatabaseManager {
    private var topDocument: QueryDocumentSnapshot?
    private var bottomDocument: QueryDocumentSnapshot?
    private var listenerNew: ListenerRegistration?
    
    var delegate: DatabaseManagerDelegate?
    private let db = Firestore.firestore()
    
    // MARK: - function for sending data to server
    func sendMessage(_ message: MessageModel) {
        let data = message.convertToDictionary()
        
        db.collection(K.Database.collectionName).addDocument(data: data)
    }
    
    // MARK: - fetch messages from server on loading chat
    func fetchLast(_ number: Int) {
        self.topDocument = nil
        self.bottomDocument = nil
        self.listenerNew?.remove()
        self.listenerNew = nil
        
        db.collection(K.Database.collectionName)
            .order(by: K.Database.dateField, descending: true)
            .limit(to: number)
            .getDocuments { querySnapshot, error in
                switch error {
                case .some(let error):
                    self.delegate?.didReceiveError(self, error: error)
                case .none:
                    guard let snapshot = querySnapshot else { return }
                    
                    if snapshot.count > 0 {
                        // set documents points to future fetching
                        self.bottomDocument = snapshot.documents.first
                        self.topDocument = snapshot.documents.last
                    }
                    let data = snapshot.documents
                    let messages: [MessageModel] = data.compactMap { $0.data().asMessageModel() }.reversed()
                    // send this data to chat
                    self.delegate?.didReceiveMessages(self, messages: messages)
                    self.addListenerForNewMessages()
                }
            }
    }
    
    // MARK: - fetch messages from history
    func fetchPrevious(_ number: Int) {
        if let topDocument = self.topDocument {
            db.collection(K.Database.collectionName)
                .order(by: K.Database.dateField, descending: true)
                .start(afterDocument: topDocument)
                .limit(to: number)
                .getDocuments { querySnapshot, error in
                    switch error {
                    case .some(let error):
                        self.delegate?.didReceiveError(self, error: error)
                    case .none:
                        guard let snapshot = querySnapshot else { return }
                        
                        if snapshot.count > 0 {
                            // set new top point for the future
                            self.topDocument = snapshot.documents.last
                        }
                        let data = snapshot.documents
                        let messages: [MessageModel] = data.compactMap { $0.data().asMessageModel() }.reversed()
                        
                        // send this data to chat
                        self.delegate?.didReceiveMessages(self, messages: messages)
                    }
                }
        } else {
            db.collection(K.Database.collectionName)
                .order(by: K.Database.dateField, descending: true)
                .limit(to: number)
                .getDocuments { querySnapshot, error in
                    switch error {
                    case .some(let error):
                        self.delegate?.didReceiveError(self, error: error)
                    case .none:
                        guard let snapshot = querySnapshot else { return }
                        
                        if snapshot.count > 0 {
                            // set new top point for the future
                            self.topDocument = snapshot.documents.last
                        }
                        let data = snapshot.documents
                        let messages: [MessageModel] = data.compactMap { $0.data().asMessageModel() }.reversed()
                        
                        // send this data to chat
                        self.delegate?.didReceiveMessages(self, messages: messages)
                    }
                }
        }
    }
    
    // MARK: - listener for new messages
    func addListenerForNewMessages() {
        // remove previous listener
        self.listenerNew?.remove()
        
        if let bottomDocument = self.bottomDocument {
            // set new listener
            self.listenerNew = db.collection(K.Database.collectionName)
                .order(by: K.Database.dateField)
                .start(afterDocument: bottomDocument)
                .addSnapshotListener { querySnapshot, error in
                    switch error {
                    case .some(let error):
                        self.delegate?.didReceiveError(self, error: error)
                    case .none:
                        guard let snapshot = querySnapshot else { return }
                        
                        if snapshot.count > 0 {
                            // set new point for fetching
                            self.bottomDocument = snapshot.documents.last
                            
                            if self.topDocument == nil {
                                self.topDocument = snapshot.documents.first
                            }
                            
                            let data = snapshot.documents
                            let messages = data.compactMap { $0.data().asMessageModel() }
                            
                            // send this data to chat
                            self.delegate?.listenerDidReceiveMessages(self, messages: messages)
                            // when listener finished its job make new listener
                            self.addListenerForNewMessages()
                        }
                    }
                }
        } else {
            self.listenerNew = db.collection(K.Database.collectionName)
                .order(by: K.Database.dateField)
                .addSnapshotListener { querySnapshot, error in
                    switch error {
                    case .some(let error):
                        self.delegate?.didReceiveError(self, error: error)
                    case .none:
                        guard let snapshot = querySnapshot else { return }
                        
                        if snapshot.count > 0 {
                            // set new point for fetching
                            self.bottomDocument = snapshot.documents.last
                            
                            if self.topDocument == nil {
                                self.topDocument = snapshot.documents.first
                            }
                            
                            let data = snapshot.documents
                            let messages = data.compactMap { $0.data().asMessageModel() }
                            
                            // send this data to chat
                            self.delegate?.listenerDidReceiveMessages(self, messages: messages)
                            // when listener finished its job make new listener
                            self.addListenerForNewMessages()
                        }
                    }
                }
        }
    }
}
