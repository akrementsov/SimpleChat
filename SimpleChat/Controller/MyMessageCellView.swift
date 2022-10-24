//
//  TableViewCell.swift
//  SimpleChat
//
//  Created by Andrey on 10/10/22.
//

import UIKit
import Firebase

class MyMessageCellView: UITableViewCell {
    
    lazy private var container: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    lazy private var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = K.BottomBarViewSettings.textViewHeight/2
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    lazy private var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    lazy private var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 9)
        label.textColor = .systemGray2
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    func configureCellFor(_ message: MessageModel) {
        let date = message.date.dateValue()
        let timeformat = DateFormatter()
        timeformat.dateFormat = "HH:mm"
        let strTime = timeformat.string(from: date)
        
        self.dateLabel.text = strTime
        self.messageLabel.text = message.message
        self.backgroundColor = .clear
        self.contentView.addSubview(self.container)
        self.container.addSubview(self.bgView)
        self.container.addSubview(self.messageLabel)
        self.container.addSubview(self.dateLabel)
        self.bgView.backgroundColor = K.Colors.superLightGreen
        self.constraints()
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            self.container.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.container.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.container.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.container.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            self.bgView.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 2),
            self.bgView.leadingAnchor.constraint(greaterThanOrEqualTo: self.container.leadingAnchor, constant: 40),
            self.bgView.trailingAnchor.constraint(equalTo: self.container.trailingAnchor, constant: -10),
            self.bgView.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -2)
        ])
        
        NSLayoutConstraint.activate([
            self.dateLabel.bottomAnchor.constraint(equalTo: self.bgView.bottomAnchor, constant: -8),
            self.dateLabel.trailingAnchor.constraint(equalTo: self.bgView.trailingAnchor, constant: -8),
            self.dateLabel.widthAnchor.constraint(equalToConstant: 25)
        ])
        
        NSLayoutConstraint.activate([
            self.messageLabel.leadingAnchor.constraint(equalTo: self.bgView.leadingAnchor, constant: 10),
            self.messageLabel.topAnchor.constraint(equalTo: self.bgView.topAnchor, constant: 8),
            self.messageLabel.trailingAnchor.constraint(equalTo: self.dateLabel.leadingAnchor, constant: -6),
            self.messageLabel.bottomAnchor.constraint(equalTo: self.bgView.bottomAnchor, constant: -8)
        ])
    }
}

