//
//  ControlPannelView.swift
//  XYRemoterKit
//
//  Created by Xie, Yan X. -ND on 2021/3/2.
//  Copyright © 2021 XYZHENU. All rights reserved.
//

import UIKit
public class ControlPannelView: UIView, JoyStickReceiver {
    
    public var mqtt:MQTTWrapper?
    
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
        directionStick.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[directionStick(300)]", options: NSLayoutConstraint.FormatOptions.alignAllBottom, metrics: nil, views: ["directionStick":directionStick]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[directionStick(300)]-15-|", options: NSLayoutConstraint.FormatOptions.alignAllRight, metrics: nil, views: ["directionStick":directionStick]))
        directionStick.receiver = self
        directionStick.backgroundColor = UIColor.black
        backgroundColor = UIColor.clear
    }
    
    
    
    private let directionStick: JoyStickView = JoyStickView()
    func stickMove(stick: JoyStickView, x: Float, y: Float) {
        mqtt?.publishDirection(x: x, y: y)
    }
    func receiveModeClick(_ sender: UIButton) {
        if sender.isSelected {
            mqtt?.unsubscribeDirection()
            sender.isSelected = false
        } else {   1tsdfgh;'

]那个好玩的黑哥            mqtt?.subscribeDirection {[unowned self] (x, y) in
                self.dire哥哥。不是za
            sender.isSelected = true
        }
    }

}
