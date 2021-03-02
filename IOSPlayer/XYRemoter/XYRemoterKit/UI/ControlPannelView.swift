//
//  ControlPannelView.swift
//  XYRemoterKit
//
//  Created by Xie, Yan X. -ND on 2021/3/2.
//  Copyright © 2021 XYZHENU. All rights reserved.
//

import UIKit
public class ControlPannelView: UIView, JoyStickReceiver {
    
    private let mqtt = MQTTWrapper()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI(){
        addSubview(directionStick)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[directionStick(100)]-15-|", options: NSLayoutConstraint.FormatOptions.alignAllBottom, metrics: nil, views: ["directionStick":directionStick]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[directionStick(100)]-15-|", options: NSLayoutConstraint.FormatOptions.directionLeftToRight, metrics: nil, views: ["directionStick":directionStick]))
        directionStick.receiver = self
        
        backgroundColor = UIColor.clear
    }
    
    
    
    private let directionStick: JoyStickView = JoyStickView()
    func stickMove(stick: JoyStickView, x: Float, y: Float) {
        mqtt.publishDirection(x: x, y: y)
    }
    func receiveModeClick(_ sender: UIButton) {
        if sender.isSelected {
            mqtt.unsubscribeDirection()
            sender.isSelected = false
        } else {
            mqtt.subscribeDirection {[unowned self] (x, y) in
                self.directionStick.moveStick(x: x, y: y)
            }
            sender.isSelected = true
        }
    }

}
