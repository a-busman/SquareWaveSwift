//
//  SongTableViewCell.swift
//  VGMPRadio
//
//  Created by Alex Busman on 1/17/18.
//  Copyright © 2018 Alex Busman. All rights reserved.
//

import UIKit

class SongTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel:     UILabel?
    @IBOutlet weak var artistLabel:    UILabel?
    @IBOutlet weak var albumArtImage:  UIImageView?
    @IBOutlet weak var controlOverlay: UIView?
    
    var firstBar:  CAShapeLayer?
    var secondBar: CAShapeLayer?
    var thirdBar:  CAShapeLayer?
    var fourthBar: CAShapeLayer?

    var disliked: Bool = false
    
    var track: Track?
    
    var animating = false

    override func awakeFromNib() {
        super.awakeFromNib()
        self.stop()
        self.separatorInset = UIEdgeInsets(top: 0.0, left: 44.0, bottom: 0.0, right: 0.0)
        self.generateShapes(withAnimation: false)
        self.firstBar? .strokeEnd = 0.1
        self.secondBar?.strokeEnd = 0.1
        self.thirdBar? .strokeEnd = 0.1
        self.fourthBar?.strokeEnd = 0.1
    }

    override func prepareForReuse() {
        self.stop()
        self.disliked = false
        self.animating = false
        self.generateShapes(withAnimation: false)
        self.firstBar? .strokeEnd = 0.1
        self.secondBar?.strokeEnd = 0.1
        self.thirdBar? .strokeEnd = 0.1
        self.fourthBar?.strokeEnd = 0.1
    }
    
    func stop() {
        self.controlOverlay?.isHidden = true
        self.animating = false
    }
    
    func play() {
        self.controlOverlay?.isHidden = false
        self.generateShapes(withAnimation: true)
    }
    
    func pause() {
        self.controlOverlay?.isHidden = false
        if !self.animating {
            return
        }
        self.firstBar? .removeAllAnimations()
        self.secondBar?.removeAllAnimations()
        self.thirdBar? .removeAllAnimations()
        self.fourthBar?.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        self.firstBar? .strokeEnd = 0.1
        self.secondBar?.strokeEnd = 0.1
        self.thirdBar? .strokeEnd = 0.1
        self.fourthBar?.strokeEnd = 0.1
        CATransaction.commit()
        self.animating = false
    }
    
    func setDisliked() {
        self.disliked = true
        self.titleLabel? .textColor = .gray
        self.artistLabel?.textColor = .gray
    }
    
    func generateShapes(withAnimation animation: Bool) {
        self.firstBar? .removeFromSuperlayer()
        self.secondBar?.removeFromSuperlayer()
        self.thirdBar? .removeFromSuperlayer()
        self.fourthBar?.removeFromSuperlayer()
        self.firstBar? .removeAllAnimations()
        self.secondBar?.removeAllAnimations()
        self.thirdBar? .removeAllAnimations()
        self.fourthBar?.removeAllAnimations()
        
        self.firstBar  = self.createBar(from: CGPoint(x: 8.0, y: 32.0), to: CGPoint(x: 8.0, y: 8.0))
        self.secondBar = self.createBar(from: CGPoint(x: 16.0, y: 32.0), to: CGPoint(x: 16.0, y: 8.0))
        self.thirdBar  = self.createBar(from: CGPoint(x: 24.0, y: 32.0), to: CGPoint(x: 24.0, y: 8.0))
        self.fourthBar = self.createBar(from: CGPoint(x: 32.0, y: 32.0), to: CGPoint(x: 32.0, y: 8.0))
        
        self.controlOverlay?.layer.addSublayer(self.firstBar!)
        self.controlOverlay?.layer.addSublayer(self.secondBar!)
        self.controlOverlay?.layer.addSublayer(self.thirdBar!)
        self.controlOverlay?.layer.addSublayer(self.fourthBar!)
        if animation {
            self.animating = true
            self.addAnimation(bar: self.firstBar, forKey: "firstBarAnimation")
            self.addAnimation(bar: self.secondBar, forKey: "secondBarAnimation")
            self.addAnimation(bar: self.thirdBar, forKey: "thirdBarAnimation")
            self.addAnimation(bar: self.fourthBar, forKey: "fourthBarAnimation")
        } else {
            self.animating = false
        }
    }
    
    private func createBar(from start: CGPoint, to end: CGPoint) -> CAShapeLayer {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        
        let bar = CAShapeLayer()
        bar.fillColor = UIColor.white.cgColor
        bar.strokeColor = UIColor.white.cgColor
        bar.lineWidth = 3.0
        bar.path = path.cgPath
        
        return bar
    }
    
    private func addAnimation(bar: CAShapeLayer?, forKey key: String) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        let rand = CGFloat(drand48())
        animation.fromValue = 0.1
        animation.toValue = rand * 0.8 + 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animation.duration = (Double(rand) * 0.3) + 0.3
        animation.repeatCount = .infinity
        animation.autoreverses = true
        
        bar?.add(animation, forKey: key)
    }
}
