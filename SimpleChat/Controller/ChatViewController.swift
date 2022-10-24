//
//  ChatViewController.swift
//  SimpleChat
//
//  Created by Andrey on 10/17/22.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var constraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    private var _inputAccessoryView = BottomBarView()
    
    private var messages = [MessageModel]()
    private var isWatched = [Bool]()
    private var newHistoryMessages = [MessageModel]()
    private var newMessages = [MessageModel]()
    private let authManager = AuthManager()
    private let databaseManager = DatabaseManager()
    private var keyboardIsShown = false
    private var canAddMessages = true
    private var messagesButtonIsShown = false
    private var addOldMessagesTimer: Timer?
    private var addNewMessageTimer: Timer?
    private var bottomInset: CGFloat = 5
    private var topInset: CGFloat = 5
    
    private var isTableViewAtBottom: Bool {
        let offset = self.tableView.contentOffset.y + self.tableView.frame.height - self.tableView.contentInset.bottom
        let contentHeight = self.tableView.contentSize.height
        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
        let lastMessageHeigh = self.tableView.rectForRow(at: indexPath).height
        
        if offset > contentHeight - lastMessageHeigh - 50 {
            return true
        } else {
            return false
        }
    }
    
    lazy private var titleView: UIView = {
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let imageView = UIImageView(image: K.logo)
        imageView.frame = CGRect(x: 0, y: 0, width: titleView.frame.width, height: titleView.frame.height - 3)
        imageView.contentMode = .scaleAspectFit
        titleView.addSubview(imageView)
        return titleView
    }()
    
    lazy private var badInternetAlert: UIAlertController = {
        let alert = UIAlertController(title: "Bad internet connection", message: nil, preferredStyle: .alert)
        let button = UIAlertAction(title: "Ok", style: .cancel)
        alert.addAction(button)
        return alert
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configure()
        // fetch 20 messages
        self.databaseManager.fetchLast(20)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let inputAccessoryViewHeight = self.inputAccessoryView?.frame.height {
            // 50 - this is the hight of the showNewMessagesButton in bottom bar view + spacing
            let constraintConstant = inputAccessoryViewHeight - 50 - self.view.safeAreaInsets.bottom
            self.constraint.constant = constraintConstant
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override var inputAccessoryView: UIView? {
        return _inputAccessoryView
    }
    // it shows bottom bar
    override var canBecomeFirstResponder: Bool {
        return true
    }
    // its important to place observers here if not it makes glitches because canBecomeFirstResponder send notification too
    override var canResignFirstResponder: Bool {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.view.endEditing(true)
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIBarButtonItem) {
        self.authManager.logOut()
        self.messages = []
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func accountButtonPressed(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "accountSegue", sender: nil)
    }
}

// MARK: - Functions
extension ChatViewController {
    private func configure() {
        self.backgroundImage.image = UIImage(named: "tableViewBG")
        self.tableView.backgroundColor = .clear
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.addRefreshing()
        
        self.databaseManager.delegate = self
        self._inputAccessoryView.delegate = self
        
        self.navigationItem.hidesBackButton = true
        self.navigationItem.titleView = titleView
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = K.Colors.bg
        
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func sendMessage(_ messageBody: String) {
        guard let userName = Auth.auth().currentUser?.displayName,
              let userUID = Auth.auth().currentUser?.uid else { return }
        
        let date = Timestamp(date: Date())
        let message = MessageModel(userUID: userUID, userName: userName, message: messageBody, date: date)
        
        self.databaseManager.sendMessage(message)
    }
    
    private func moveDown() {
        self.tableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .top, animated: true)
    }
    
    // this is the func for testing
    private func addMessages() {
        var count = 0
        
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
            let str = String(format: "%03d", count)
            self.sendMessage(str)
            count += 1
            
            if count == 25 {
                timer.invalidate()
            }
        }
    }
    
    private func setNewInsets(bottomInset: CGFloat) {
        let height = self.tableView.frame.height
        let contentHeight = self.tableView.contentSize.height
        var topInset: CGFloat = 0
        
        if contentHeight >= height - bottomInset - self.topInset {
            topInset = self.topInset
        } else {
            topInset = height - contentHeight - bottomInset
        }
        
        self.tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
    }
    
    private func addRefreshing() {
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.addTarget(self, action: #selector(loadHistory(_:)), for: .valueChanged)
    }
    
    private func checkNewMessages() {
        // its important to show the button with delay, otherwise it flicks
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.isWatched.contains(false) {
                self._inputAccessoryView.showButton()
            } else {
                self._inputAccessoryView.hideButton()
            }
        }
    }
    
    @objc private func keyboardWillShow(_ sender: Notification) {
        if !self.keyboardIsShown {
            guard let keyboardFrame = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                  let curve = sender.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
                  let duration = sender.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
                  let inputAccView = self.inputAccessoryView else { return }
            
            self.keyboardIsShown = true
            let point = self.tableView.contentOffset
            let newInset = keyboardFrame.height - inputAccView.frame.height - self.view.safeAreaInsets.bottom + self.bottomInset
            let newOffset = point.y + keyboardFrame.height - inputAccView.frame.height - self.view.safeAreaInsets.bottom
            
            UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: [UIView.AnimationOptions(rawValue: curve)]) {
                self.tableView.contentOffset.y = newOffset
                self.view.layoutIfNeeded()
            } completion: { _ in
                // if I set insets in animation part it makes glitches
                self.setNewInsets(bottomInset: newInset)
            }
        }
    }
    
    @objc private func keyboardWillHide(_ sender: Notification) {
        if self.keyboardIsShown {
            guard let curve = sender.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
                  let duration = sender.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
            
            self.keyboardIsShown = false
            NotificationCenter.default.removeObserver(self)
            
            UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: [UIView.AnimationOptions(rawValue: curve)]) {
                self.setNewInsets(bottomInset: self.bottomInset)
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc private func loadHistory(_ sender: UIRefreshControl) {
        self.databaseManager.fetchPrevious(20)
    }
}

// MARK: - TableView
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let message = messages[index]
        
        if message.userUID == Auth.auth().currentUser?.uid {
            let cell = tableView.dequeueReusableCell(withIdentifier: K.myCellIdentifier, for: indexPath) as! MyMessageCellView
            cell.configureCellFor(message)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: K.thereCellIdentifier, for: indexPath) as! ThereMessageCellView
            cell.configureCellFor(message)
            return cell
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.canAddMessages = true
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.canAddMessages = false
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.isWatched[indexPath.row] = true
        self.checkNewMessages()
    }
}

// MARK: - DatabaseManagerDelegate
extension ChatViewController: DatabaseManagerDelegate {
    func didReceiveMessages(_ databaseManager: DatabaseManager, messages: [MessageModel]) {
        // receive messages on loading chat
        if self.messages.isEmpty {
            self.messages = messages
            self.isWatched = [Bool](repeating: true, count: messages.count)
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.setNewInsets(bottomInset: self.bottomInset)
            if messages.count > 0 {
                self.tableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .top, animated: false)
            }
        } else {
            // receive messages when load history
            self.newHistoryMessages.append(contentsOf: messages)
            self.addOldMessagesTimer?.invalidate()
            self.addOldMessagesTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                // while table view is being scrolled keep waiting
                if self.canAddMessages {
                    self.tableView.refreshControl?.endRefreshing()
                    self.messages.insert(contentsOf: self.newHistoryMessages, at: 0)
                    self.isWatched.insert(contentsOf: [Bool](repeating: true, count: self.newHistoryMessages.count), at: 0)
                    self.tableView.reloadData()
                    self.tableView.layoutIfNeeded()
                    let inset = self.tableView.contentInset.bottom
                    self.setNewInsets(bottomInset: inset)
                    self.newHistoryMessages = []
                    self.addOldMessagesTimer?.invalidate()
                }
            }
        }
    }
    
    // listener to add new messages
    func listenerDidReceiveMessages(_ databaseManager: DatabaseManager, messages: [MessageModel]) {
        self.newMessages.append(contentsOf: messages)
        
        self.addNewMessageTimer?.invalidate()
        self.addNewMessageTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if self.canAddMessages {
                self.isWatched.append(contentsOf: [Bool](repeating: false, count: self.newMessages.count))
                self.messages.append(contentsOf: self.newMessages)
                self.tableView.reloadData()
                self.view.layoutIfNeeded()
    
                UIView.animate(withDuration: 0.25) {
                    if self.tableView.contentInset.bottom < 0 {
                        self.setNewInsets(bottomInset: self.bottomInset)
                    } else {
                        self.setNewInsets(bottomInset: self.tableView.contentInset.bottom)
                    }
                    self.view.layoutIfNeeded()
                }

                if let message = self.newMessages.first,
                   message.userUID == Auth.auth().currentUser?.uid {
                    self.moveDown()
                }
                
                if self.isTableViewAtBottom {
                    self.moveDown()
                }
                
                self.newMessages = []
                timer.invalidate()
            }
        }
    }
    
    func didReceiveError(_ databaseManager: DatabaseManager, error: Error) {
        let error = error as NSError
        let errorAuthCode = AuthErrorCode(_nsError: error)
        let errorCode = errorAuthCode.code
        
        switch errorCode {
        case .networkError:
            self.present(badInternetAlert, animated: true)
        default: break
        }
    }
}

// MARK: - BottomBarDelegate
extension ChatViewController: BottomBarViewDelegate {
    func showNewMessages(_ bottomBarView: BottomBarView) {
        self.moveDown()
    }
    
    func sendButtonDidPress(_ bottomBarView: BottomBarView, text: String) {
        self.sendMessage(text)
    }
    
    func textDidChange(_ bottomBarView: BottomBarView, height: CGFloat) {
        let offset = self.tableView.contentInset.bottom + height
        
        UIView.animate(withDuration: K.Animation.textViewDidChangeDuration) {
            self.tableView.contentOffset.y += height
            self.setNewInsets(bottomInset: offset)
            self.view.layoutIfNeeded()
        }
    }
}
