//
//  ListArtView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/15/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI
import UIKit

class AnimatedUIView: UIView {
    private var _isAnimated = false
    var isAnimated: Bool {
        get {
            return _isAnimated
        }
        set(newValue) {
            if newValue {
                generateShapes(withAnimation: true)
            } else {
                self.firstBar?.removeAllAnimations()
                self.secondBar?.removeAllAnimations()
                self.thirdBar?.removeAllAnimations()
                self.fourthBar?.removeAllAnimations()
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.5)
                self.firstBar?.strokeEnd = 0.1
                self.secondBar?.strokeEnd = 0.1
                self.thirdBar?.strokeEnd = 0.1
                self.fourthBar?.strokeEnd = 0.1
                CATransaction.commit()
            }
        }
    }
    
    var firstBar:  CAShapeLayer?
    var secondBar: CAShapeLayer?
    var thirdBar:  CAShapeLayer?
    var fourthBar: CAShapeLayer?
    
    var firstBase:  CAShapeLayer?
    var secondBase: CAShapeLayer?
    var thirdBase:  CAShapeLayer?
    var fourthBase: CAShapeLayer?
    
    init() {
        super.init(frame: .zero)
        self.generateShapes(withAnimation: false)
    }
    
    init(isAnimated: Bool) {
        super.init(frame: .zero)
        self.generateShapes(withAnimation: isAnimated)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.generateShapes(withAnimation: false)
    }
    
    func generateShapes(withAnimation animation: Bool) {
        let rand1: CGFloat = CGFloat(drand48())
        let rand2: CGFloat = CGFloat(drand48())
        let rand3: CGFloat = CGFloat(drand48())
        let rand4: CGFloat = CGFloat(drand48())
        
        self.firstBar?.removeFromSuperlayer()
        self.secondBar?.removeFromSuperlayer()
        self.thirdBar?.removeFromSuperlayer()
        self.fourthBar?.removeFromSuperlayer()
        self.firstBar?.removeAllAnimations()
        self.secondBar?.removeAllAnimations()
        self.thirdBar?.removeAllAnimations()
        self.fourthBar?.removeAllAnimations()
        
        let path1 = UIBezierPath()
        let path2 = UIBezierPath()
        let path3 = UIBezierPath()
        let path4 = UIBezierPath()
                
        path1.move(to: CGPoint(x: 6.8, y: 26.0))
        path1.addLine(to: CGPoint(x: 6.8, y: 8.0))
        
        path2.move(to: CGPoint(x: 13.6, y: 26.0))
        path2.addLine(to: CGPoint(x: 13.6, y: 8.0))
        
        path3.move(to: CGPoint(x: 20.4, y: 26.0))
        path3.addLine(to: CGPoint(x: 20.4, y: 8.0))
        
        path4.move(to: CGPoint(x: 27.2, y: 26.0))
        path4.addLine(to: CGPoint(x: 27.2, y: 8.0))
        
        self.firstBar = CAShapeLayer()
        self.firstBar?.fillColor = UIColor.white.cgColor
        self.firstBar?.strokeColor = UIColor.white.cgColor
        self.firstBar?.lineWidth = 3.0
        self.firstBar?.path = path1.cgPath
        
        self.secondBar = CAShapeLayer()
        self.secondBar?.fillColor = UIColor.white.cgColor
        self.secondBar?.strokeColor = UIColor.white.cgColor
        self.secondBar?.lineWidth = 3.0
        self.secondBar?.path = path2.cgPath
        
        self.thirdBar = CAShapeLayer()
        self.thirdBar?.fillColor = UIColor.white.cgColor
        self.thirdBar?.strokeColor = UIColor.white.cgColor
        self.thirdBar?.lineWidth = 3.0
        self.thirdBar?.path = path3.cgPath
        
        self.fourthBar = CAShapeLayer()
        self.fourthBar?.fillColor = UIColor.white.cgColor
        self.fourthBar?.strokeColor = UIColor.white.cgColor
        self.fourthBar?.lineWidth = 3.0
        self.fourthBar?.path = path4.cgPath
        
        self.layer.addSublayer(self.firstBar!)
        self.layer.addSublayer(self.secondBar!)
        self.layer.addSublayer(self.thirdBar!)
        self.layer.addSublayer(self.fourthBar!)
        if animation {
            let animation1 = CABasicAnimation(keyPath: "strokeEnd")
            animation1.fromValue = 0.1
            animation1.toValue = rand1 * 0.8 + 0.2
            animation1.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            animation1.duration = (Double(rand1) * 0.3) + 0.3
            animation1.repeatCount = .infinity
            animation1.autoreverses = true
            
            let animation2 = CABasicAnimation(keyPath: "strokeEnd")
            animation2.fromValue = 0.1
            animation2.toValue = rand2 * 0.8 + 0.2
            animation2.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            animation2.duration = (Double(rand2) * 0.3) + 0.3
            animation2.repeatCount = .infinity
            animation2.autoreverses = true
            
            let animation3 = CABasicAnimation(keyPath: "strokeEnd")
            animation3.fromValue = 0.1
            animation3.toValue = rand3 * 0.8 + 0.2
            animation3.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            animation3.duration = (Double(rand3) * 0.3) + 0.3
            animation3.repeatCount = .infinity
            animation3.autoreverses = true
            
            let animation4 = CABasicAnimation(keyPath: "strokeEnd")
            animation4.fromValue = 0.1
            animation4.toValue = rand4 * 0.8 + 0.2
            animation4.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            animation4.duration = (Double(rand4) * 0.3) + 0.3
            animation4.repeatCount = .infinity
            animation4.autoreverses = true
            
            self.firstBar?.add(animation1, forKey: "firstBarAnimation")
            self.secondBar?.add(animation2, forKey: "secondBarAnimation")
            self.thirdBar?.add(animation3, forKey: "thirdBarAnimation")
            self.fourthBar?.add(animation4, forKey: "fourthBarAnimation")
        }
    }
}

class AnimationSettings: ObservableObject {
    @Published var isAnimated:  Bool = false
    @Published var isDisplayed: Bool = false
    
    func startAnimating() {
        self.isAnimated  = true
        self.isDisplayed = true
    }
    
    func pauseAnimating() {
        self.isDisplayed = true
        self.isAnimated  = false
    }
    
    func hideAnimation() {
        self.isDisplayed = false
        self.isAnimated  = false
    }
}

struct AnimatedView: UIViewRepresentable {
    @Binding var isAnimated: Bool
    
    func makeUIView(context: UIViewRepresentableContext<AnimatedView>) -> AnimatedUIView {
        return AnimatedUIView(isAnimated: self.isAnimated)
    }
    
    func updateUIView(_ uiView: AnimatedUIView, context: UIViewRepresentableContext<AnimatedView>) {
        uiView.isAnimated = self.isAnimated
    }
}

struct ListArtView: View {
    @ObservedObject var animationSettings: AnimationSettings
    @State var isAnimated: Bool = false
    var albumArt: String = ""
    let cornerRadius: CGFloat = 4.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Image(uiImage: ListArtView.getImage(for: self.albumArt) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(4.0)
                    .overlay(RoundedRectangle(cornerRadius: self.cornerRadius).stroke(Color(.lightGray), lineWidth: 0.5))
                if (self.animationSettings.isDisplayed) {
                    Rectangle()
                        .foregroundColor(.black)
                        .opacity(0.6)
                        .cornerRadius(self.cornerRadius)
                    AnimatedView(isAnimated: self.$isAnimated)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }.onReceive(animationSettings.objectWillChange, perform: { _ in
            self.isAnimated = self.animationSettings.isAnimated
        })
    }
    
    enum StringMap: String {
        case msx        = "MSX"
        case nes        = "Nintendo NES"
        case snes       = "Super Nintendo"
        case atari      = "Atari XL"
        case smsgenesis = "Sega SMS/Genesis"
        case gameboy    = "Game Boy"
        case spectrum   = "ZX Spectrum"
        case turbo      = "TurboGrafx"
    }
    
    static func getImage(for system: String) -> UIImage? {
        var imageName: String = ""
        switch (system) {
        case StringMap.msx.rawValue:
            imageName = "msx"
        case StringMap.nes.rawValue:
            imageName = "nes"
        case StringMap.snes.rawValue:
            imageName = "snes"
        case StringMap.atari.rawValue:
            imageName = "atari"
        case StringMap.smsgenesis.rawValue:
            imageName = "megadrive"
        case StringMap.gameboy.rawValue:
            imageName = "gameboy"
        case StringMap.spectrum.rawValue:
            imageName = "spectrum"
        case StringMap.turbo.rawValue:
            imageName = "turbografx"
        default:
            return nil
        }
        return UIImage(named: imageName)
    }
}

struct ListArtView_Previews: PreviewProvider {
    static var previews: some View {
        ListArtView(animationSettings: AnimationSettings())
    }
}
