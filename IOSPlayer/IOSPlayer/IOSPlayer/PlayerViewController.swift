//
//  PlayerViewController.swift
//  IOSPlayer
//
//  Created by XYZHENU on 2021/3/2.
//  Copyright © 2021 yan.xie. All rights reserved.
//

import UIKit
import MediaPlayerKit
import XYRemoterKit
class PlayerViewController: UIViewController {
    var mqttaddress:String?
    var videoaddress:String?
    
    @IBOutlet weak var player: StreamPlayer!
    @IBOutlet weak var controlPannel: ControlPannelView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let add = mqttaddress {
            controlPannel.mqtt = MQTTWrapper(host: add)
        }
        if let add = videoaddress {
            player.play(add)
        }
    }
}
