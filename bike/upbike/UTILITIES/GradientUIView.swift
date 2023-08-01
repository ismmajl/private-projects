//
//  GradientUIView.swift
//  combike

import UIKit

@IBDesignable
class GradientUIView: UIView {
    
    fileprivate let gradientLayer = CAGradientLayer()
    
    @IBInspectable var color1: UIColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) { didSet { updateColors() } }
    @IBInspectable var color2: UIColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)  { didSet { updateColors() } }
    
    @IBInspectable var gradientHorizontal : Bool = true {
        didSet {
            configureGradient()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureGradient()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureGradient()
    }
    
    func configureGradient() {
        
        if(gradientHorizontal) {
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        } else {
            gradientLayer.startPoint = CGPoint(x:0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        }
        
        updateColors()
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    fileprivate func updateColors() {
        gradientLayer.colors = [color1.cgColor, color2.cgColor]
    }
}
