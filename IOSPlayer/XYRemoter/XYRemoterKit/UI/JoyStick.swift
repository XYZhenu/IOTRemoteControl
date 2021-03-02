//
//  File.swift
//  XYRemoterKit
//
//  Created by XYZHENU on 2020/9/13.
//  Copyright © 2020 XYZHENU. All rights reserved.
//

import UIKit

@objc protocol JoyStickReceiver {
    func stickMove(stick:JoyStickView, x:Float, y:Float)
}

class JoyStickView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    var strokeColor = UIColor.white
    
    private let stickPoint = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
    private func setupUI() {
        isUserInteractionEnabled = true
        backgroundColor = UIColor.clear
        layer.masksToBounds = false
        stickPoint.backgroundColor = strokeColor
        stickPoint.alpha = 0.7
        stickPoint.layer.cornerRadius = stickPoint.frame.size.width / 2
        addSubview(stickPoint)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateStickPosition()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        context?.setShadow(offset: CGSize.zero, blur: 4, color: UIColor.red.cgColor)
        
        let radius = rect.size.width / 2
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius), radius: radius - 4, startAngle: 0, endAngle: CGFloat(Float.pi * 2), clockwise: true)
        strokeColor.setStroke()
        circlePath.stroke()
        
        context?.restoreGState()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateStick(location: positionCaculate(point: touch.location(in: self)))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateStick(location: positionCaculate(point: touch.location(in: self)))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateStick(location: positionCaculate(point: touch.location(in: self)))
        resetStick()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetStick()
    }
    
    private func positionCaculate(point:CGPoint) -> (CGPoint, CGPoint) {
        
        let centrex = self.frame.size.width / 2;          //圆心X
        let centrey = self.frame.size.height / 2;         //圆心Y
        let radius = self.frame.size.width / 2;           //半径
        var x:CGFloat = 0;              //坐标系X
        var y:CGFloat = 0;              //坐标系Y
        
        x = point.x - centrex;
        y = point.y - centrey;
        
        let current_radius =  CGFloat(sqrtf(Float(x*x + y*y)));           //计算点到圆心的距离
        if(current_radius > radius)
        {
            let rate = radius / current_radius
            x = x * rate;
            y = y * rate;
            
            return (CGPoint(x: centrex + x, y: centrey + y), CGPoint(x: x / radius, y: -y / radius));
        }
        else
        {
            return (point, CGPoint(x: x / radius, y: -y / radius));
        }
    }
    
    weak var receiver: JoyStickReceiver?
    private func updateStick(location: (position:CGPoint, rate:CGPoint)) {
        stickPoint.center = location.position
        receiver?.stickMove(stick: self, x: Float(location.rate.x), y: Float(location.rate.y))
    }
    private func resetStick() {
        self.receiver?.stickMove(stick: self, x: 0, y: 0)
        UIView.animate(withDuration: 0.3) {
            self.updateStickPosition()
        }
    }
    private func updateStickPosition() {
        let centrex = self.frame.size.width / 2
        let centrey = self.frame.size.height / 2;
        self.stickPoint.center = CGPoint(x: centrex, y: centrey)
    }
    
    func moveStick(x:Float, y:Float) {
        if fabsf(x) < 0.01, fabsf(y) < 0.01 {
            UIView.animate(withDuration: 0.3) {
                self.updateStickPosition()
            }
        } else {
            let radius = self.frame.size.width / 2
            let centrex = radius
            let centrey = self.frame.size.height / 2
            self.stickPoint.center = CGPoint(x: centrex + CGFloat(x) * radius, y: centrey + CGFloat(-y) * radius)
        }
    }
}
