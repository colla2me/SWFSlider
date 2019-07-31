//
//  BetterSlider.swift
//  ObjCDemo
//
//  Created by Samuel on 2019/7/26.
//  Copyright © 2019 Shenzhen Thirtydays Technology. All rights reserved.
//

import UIKit

class SWFSlider: UIControl {
    
    // MARK: Public
    
    var value: Float = 0.0 {
        didSet {
            if value < self.minimumValue {
                value = self.minimumValue
            }
            print("value: ", value)
            setNeedsLayout()
        }
    }
    
    var minimumValue: Float = 0.0
    
    var maximumValue: Float = 1.0
    
    var minimumTrackTintColor: UIColor?
    
    var maximumTrackTintColor: UIColor?

    var thumbTintColor: UIColor?
    
    var isContinuous: Bool = false
    
    func setValue(_ value: Float, animated: Bool) {
        self.value = min(value, maximumValue)
        if animated {
            updateLayerLayout()
        } else {
            setNeedsLayout()
        }
    }
    
    // MARK: Private

    private let maximumThumbDiameter: CGFloat = 28.0
    private let minimumThumbDiameter: CGFloat = 8.0
    private let trackHeight: CGFloat = 4.0
    private let thumbLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    private var thumbDiameter: CGFloat {
        return isTracking ? maximumThumbDiameter : minimumThumbDiameter
    }
    
    // MARK: Override
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        self.tintColor = UIColor.black.withAlphaComponent(0.4)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        trackLayer.fillColor = UIColor.white.withAlphaComponent(0.5).cgColor
        progressLayer.fillColor = UIColor.orange.cgColor
        thumbLayer.fillColor = UIColor.white.cgColor
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        layer.addSublayer(thumbLayer)
    }
    
    private func getOffsetAlongLineForValue(_ value: Float) -> Float {
        let percentage = getPercentAlongLineForValue(value)
        let distance = trackLayer.frame.width - thumbDiameter
        let offset = percentage * Float(distance)
        return Float(trackLayer.frame.minX) + offset + Float(thumbDiameter) * 0.5
    }
    
    private func getPercentAlongLineForValue(_ value: Float) -> Float {
        guard minimumValue < maximumValue else { return 0.0 }
        let distance = maximumValue - minimumValue
        let offset = value - minimumValue
        return offset / distance
    }
    
    private func updateLayerLayout() {
        trackLayer.frame = CGRect(x: 10, y: (frame.height - trackHeight) * 0.5, width: frame.width - 20, height: trackHeight)
        let cornerRadius = trackHeight * 0.5
        let trackPath = UIBezierPath(roundedRect: trackLayer.bounds, cornerRadius: cornerRadius)
        trackLayer.path = trackPath.cgPath
        
        let offset = CGFloat(getOffsetAlongLineForValue(value))
        let thumbRadius = thumbDiameter * 0.5
        let minX = trackLayer.frame.minX + thumbRadius
        let maxX = trackLayer.frame.maxX - thumbRadius
        
        let position = CGPoint(x: min(maxX, max(offset, minX)), y: trackLayer.frame.midY)
        thumbLayer.frame.size = CGSize(width: thumbDiameter, height: thumbDiameter)
        thumbLayer.position = position
        
        let thumbPath = UIBezierPath(roundedRect: thumbLayer.bounds, cornerRadius: thumbDiameter * 0.5)
        thumbLayer.path = thumbPath.cgPath
        
        var roundedRect = trackLayer.frame
        roundedRect.size.width = position.x - trackLayer.frame.minX
        progressLayer.path = UIBezierPath(roundedRect: roundedRect, cornerRadius: cornerRadius).cgPath
    }
    
    // MARK: Override
    
    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateLayerLayout()
        CATransaction.commit()
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        trackLayer.backgroundColor = self.tintColor.cgColor;
        CATransaction.commit()
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        let offset = minimumThumbDiameter - maximumThumbDiameter
        let touchRect = thumbLayer.frame.insetBy(dx: offset, dy: offset)
        if touchRect.contains(location) {
            animateThumb(withSelection: true)
            setNeedsLayout()
            return true
        }
        return false
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        let offset = location.x - trackLayer.frame.minX - thumbDiameter * 0.5
        let distance = trackLayer.frame.width - thumbDiameter
        let percentage = offset / distance
        let progress = Float(percentage) * (maximumValue - minimumValue) + minimumValue
        self.value = min(progress, maximumValue)
        if isContinuous {
            sendActions(for: .valueChanged)
        }
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        animateThumb(withSelection: false)
        setNeedsLayout()
        if !isContinuous {
            sendActions(for: .valueChanged)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 36.0)
    }
    
    // MARK: Animation
    
    private func animateThumb(withSelection isSelected: Bool) {
        if isSelected {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.26)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            let scale = maximumThumbDiameter / minimumThumbDiameter
            thumbLayer.transform = CATransform3DMakeScale(scale, scale, 1)
            CATransaction.commit()
        } else {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.26)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            thumbLayer.transform = CATransform3DIdentity
            CATransaction.commit()
        }
    }
}
