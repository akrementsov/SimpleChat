//
//  PasswordTipView.swift
//  SimpleChat
//
//  Created by Andrey on 10/8/22.
//

import Foundation
import UIKit

@IBDesignable
final class PasswordTipView: UIView {
    private let triangleWidth: CGFloat = 20
    private let triangleHeight: CGFloat = 16
    private let triangleOffset: CGFloat = 8
    private let cornerRadius: CGFloat = 1.5
    
    lazy private var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.text = K.Texts.passwordHint
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.drawToolTip(rect)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(label)
        
        NSLayoutConstraint.activate([
            self.label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            self.label.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            self.label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            self.label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -self.triangleHeight - 5)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func drawToolTip(_ rect : CGRect){
        let mainRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - self.triangleHeight)
        let roundRectPath = UIBezierPath(roundedRect: mainRect, cornerRadius: 5.0)
        
        let triangleRect = CGRect(x: mainRect.maxX - self.triangleWidth - self.triangleOffset,
                                  y: mainRect.maxY,
                                  width: self.triangleWidth,
                                  height: self.triangleHeight)
        let trianglePath = UIBezierPath()

        // right corner
        trianglePath.move(to: CGPoint(x: triangleRect.minX, y: triangleRect.minY))
        trianglePath.addLine(to: CGPoint(x: triangleRect.maxX, y: triangleRect.minY))
        
        // bottom corner
        trianglePath.addLine(to: CGPoint(x: triangleRect.midX + self.cornerRadius, y: triangleRect.maxY - self.cornerRadius))
        trianglePath.addQuadCurve(to: CGPoint(x: triangleRect.midX - self.cornerRadius, y: triangleRect.maxY - self.cornerRadius),
                                  controlPoint: CGPoint(x: triangleRect.midX, y: triangleRect.maxY))
        
        // left corner
        trianglePath.addLine(to: CGPoint(x: triangleRect.minX, y: triangleRect.minY))
        trianglePath.close()
        
        roundRectPath.append(trianglePath)
        let shape = createShapeLayer(roundRectPath.cgPath)
        self.layer.insertSublayer(shape, at: 0)
    }
    
    private func createShapeLayer(_ path : CGPath) -> CAShapeLayer{
        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = UIColor.darkGray.withAlphaComponent(0.8).cgColor
        shape.shadowColor = UIColor.black.withAlphaComponent(0.60).cgColor
        shape.shadowOffset = CGSize(width: 0, height: 0)
        shape.shadowRadius = 5.0
        shape.shadowOpacity = 0.8
        return shape
    }
    
}
