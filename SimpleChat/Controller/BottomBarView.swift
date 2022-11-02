//
//  BottomBarView.swift
//  SimpleChat
//
//  Created by Andrey on 10/4/22.
//

import Foundation
import UIKit
import AVFoundation

// Protocol for receiving data from the inputViewAccessory
protocol BottomBarViewDelegate: AnyObject {
    func sendButtonDidPress(_ bottomBarView: BottomBarView, text: String)
    func textDidChange(_ bottomBarView: BottomBarView, height: CGFloat)
    func showNewMessages(_ bottomBarView: BottomBarView)
}

final class BottomBarView: UIView {
    weak var delegate: BottomBarViewDelegate?
    private var heightConstraint: NSLayoutConstraint?

    // max height for the text view
    private let maxHeight = K.BottomBarViewSettings.maxHeight
    
    // setting up a UITextView
    lazy private var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.cornerCurve = .continuous
        textView.layer.cornerRadius = 5
        textView.font = .systemFont(ofSize: K.BottomBarViewSettings.fontSize)
        textView.delegate = self
        
        return textView
    }()
    
    lazy private var placeholderLabel: UILabel = {
        let placeholder = UILabel()
        placeholder.text = "Message"
        placeholder.font = .systemFont(ofSize: K.BottomBarViewSettings.fontSize)
        placeholder.sizeToFit()
        placeholder.textColor = .tertiaryLabel
        placeholder.frame.origin = CGPoint(x: 5, y: K.BottomBarViewSettings.fontSize / 2)
        return placeholder
    }()
    
    // setting up a sendButton
    private var sendButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let font = UIFont.systemFont(ofSize: K.BottomBarViewSettings.fontSize)
        let config = UIImage.SymbolConfiguration(font: font)
        let image = UIImage(systemName: K.BottomBarViewSettings.buttonImage, withConfiguration: config)
        button.setImage(image, for: .normal)
        
        button.backgroundColor = K.Colors.lightOrange
        button.tintColor = K.Colors.orange
        button.layer.cornerRadius = K.BottomBarViewSettings.textViewHeight/2
        button.isEnabled = false
        
        return button
    }()
    
    // setting up a button for showing new messages
    lazy private var newMessagesButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 34, weight: .medium)
        let image = UIImage(systemName: "arrow.down.circle", withConfiguration: imageConfig)
        button.setImage(image, for: .normal)
        button.backgroundColor = K.Colors.bg?.withAlphaComponent(0.6)
        button.layer.cornerRadius = button.frame.height/2
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.2
        button.tintColor = K.Colors.orange
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        button.isHidden = true
        return button
    }()
    
    lazy private var background: UIView = {
        let view = UIView()
        view.backgroundColor = K.Colors.bg
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // init self view
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // min size of the self view
    override var intrinsicContentSize: CGSize { return CGSize.zero }
    
    // make the BG transparent for touches
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
    
    // tell delegate to show new messages
    @objc private func newMessagesButtonPressed(_ sender: UIButton) {
        self.delegate?.showNewMessages(self)
    }
    
    // setting up the self view
    private func configure() {
        self.backgroundColor = .clear
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.background)
        self.addSubview(self.sendButton)
        self.addSubview(self.textView)
        self.addSubview(self.newMessagesButton)
        self.textView.addSubview(self.placeholderLabel)
        
        self.newMessagesButton.addTarget(self, action: #selector(newMessagesButtonPressed(_:)), for: .touchUpInside)
        self.sendButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        
        // constraints
        NSLayoutConstraint.activate([
            self.newMessagesButton.bottomAnchor.constraint(equalTo: self.background.topAnchor, constant: -10),
            self.newMessagesButton.trailingAnchor.constraint(equalTo: self.sendButton.trailingAnchor),
            self.newMessagesButton.heightAnchor.constraint(equalToConstant: 40),
            self.newMessagesButton.widthAnchor.constraint(equalToConstant: 40),
            self.newMessagesButton.topAnchor.constraint(equalTo: self.topAnchor)
        ])
        
        NSLayoutConstraint.activate([
            self.background.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.background.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.background.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            self.sendButton.heightAnchor.constraint(equalToConstant: K.BottomBarViewSettings.textViewHeight),
            self.sendButton.widthAnchor.constraint(equalToConstant: K.BottomBarViewSettings.textViewHeight),
            self.sendButton.bottomAnchor.constraint(equalTo: self.textView.bottomAnchor),
            self.sendButton.trailingAnchor.constraint(equalTo: self.background.trailingAnchor, constant: -10)
        ])
        
        NSLayoutConstraint.activate([
            self.textView.leadingAnchor.constraint(equalTo: self.background.leadingAnchor, constant: 10),
            self.textView.trailingAnchor.constraint(equalTo: self.sendButton.leadingAnchor, constant: -10),
            self.textView.topAnchor.constraint(equalTo: self.background.topAnchor, constant: 10),
            self.textView.bottomAnchor.constraint(lessThanOrEqualTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        // assign constraint for the future animation
        self.heightConstraint = self.textView.heightAnchor.constraint(equalToConstant: K.BottomBarViewSettings.textViewHeight)
        self.heightConstraint?.isActive = true
    }
    
    func showButton() {
        self.newMessagesButton.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.newMessagesButton.alpha = 1
        }
    }
    
    func hideButton() {
        UIView.animate(withDuration: 0.25) {
            self.newMessagesButton.alpha = 0
        } completion: { _ in
            self.newMessagesButton.isHidden = true
        }
    }
    
    // func for changing the bottom view height
    private func changeSize(_ textView: UITextView) {
        guard let superView = self.superview else { return }
        let currentHeight = textView.frame.height
        let textViewHeight = textView.contentSize.height
        let newHeight = textViewHeight <= maxHeight ? textViewHeight : maxHeight
        let currentSuperOriginY = superView.frame.origin.y
        
        if newHeight != currentHeight {
            let difference = newHeight - currentHeight
            self.heightConstraint?.constant = newHeight
            superView.frame.origin.y -= difference/2
            self.delegate?.textDidChange(self, height: difference)

            UIView.animate(withDuration: K.Animation.textViewDidChangeDuration) {
                superView.frame.origin.y = currentSuperOriginY - difference
                self.layoutIfNeeded()
            }
        }
    }
    
    // func for send data to the delegate and to process text view
    @objc private func buttonPressed(_ sender: UIButton) {
        self.delegate?.sendButtonDidPress(self, text: self.textView.text.trimSpacesAndNewLines())
        self.textView.text = ""
        self.textView.resignFirstResponder()
        self.sendButton.isEnabled = false
        self.changeSize(self.textView)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - TextViewDelegate
extension BottomBarView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.placeholderLabel.isHidden = !textView.text.isEmpty
        
        let newString = textView.text.trimSpacesAndNewLines()
        let currentHeight = textView.frame.height
        let newHeight = textView.contentSize.height
        let difference = newHeight - currentHeight
        
        if newString != "" {
            self.sendButton.isEnabled = true
        } else {
            self.sendButton.isEnabled = false
        }
        
        if difference != 0 {
            self.changeSize(textView)
        }
    }
}
