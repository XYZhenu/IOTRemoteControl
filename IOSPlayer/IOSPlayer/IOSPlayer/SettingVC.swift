//
//  SettingVC.swift
//  IOSPlayer
//
//  Created by XYZHENU on 2021/4/8.
//  Copyright © 2021 yan.xie. All rights reserved.
//

import UIKit
class SettingVC: UIViewController {
    @IBOutlet weak var videoField: UITextField!
    @IBOutlet weak var mqttField: UITextField!
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? PlayerViewController else { return }
        vc.mqttaddress = mqttField.text
        vc.videoaddress = videoField.text
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endedit)))
    }
    @objc func endedit(){
        self.view.endEditing(true)
    }
}
