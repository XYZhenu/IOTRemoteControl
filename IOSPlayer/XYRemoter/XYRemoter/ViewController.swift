//
//  ViewController.swift
//  XYRemoter
//
//  Created by XYZHENU on 2020/9/13.
//  Copyright © 2020 XYZHENU. All rights reserved.
//

import UIKit
import XYRemoterKit

class ViewController: UIViewController, JoyStickReceiver {
    func stickMove(stick: JoyStick, x: Float, y: Float) {
        mqtt.publishDirection(x: x, y: y)
    }
    
    @IBOutlet weak var stick: JoyStick!
    let mqtt = MQTTWrapper()
    
    @IBAction func receiveModeClick(_ sender: UIButton) {
        if sender.isSelected {
            mqtt.unsubscribeDirection()
            sender.isSelected = false
        } else {
            mqtt.subscribeDirection {[unowned self] (x, y) in
                self.stick.moveStick(x: x, y: y)
            }
            sender.isSelected = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.gray
        // Do any additional setup after loading the view.
        stick.receiver = self
    }
}

