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
    @IBOutlet weak var player: StreamPlayer!
    @IBOutlet weak var controlPannel: ControlPannelView!
    override func viewDidLoad() {
        super.viewDidLoad()
//        controlPannel.mqtt = MQTTWrapper()
        player.play("rtsp://192.168.1.13/test/test")
    }
}
