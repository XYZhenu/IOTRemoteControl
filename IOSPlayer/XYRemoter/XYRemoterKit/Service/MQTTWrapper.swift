//
//  MQTTWrapper.swift
//  XYRemoterKit
//
//  Created by XYZHENU on 2020/9/14.
//  Copyright © 2020 XYZHENU. All rights reserved.
//
import CocoaMQTT
class MQTTWrapper {
    
    private enum Topic : String {
        case direction
        case reset
    }
    
    private enum Reset : String {
        case direction
    }
    
    private let mqtt:CocoaMQTT
    init(clientID: String = "test", username: String = "xykit", password: String = "xykit.", host: String = "localhost", port: UInt16 = 1883) {
        mqtt = CocoaMQTT(clientID: clientID, host: host, port: port)
        mqtt.username = username
        mqtt.password = password
        mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
        mqtt.keepAlive = 60
        mqtt.delegate = self
        mqtt.connect() ? print("connect success") : print("connect failed")
    }
    
    func publishDirection(x:Float, y:Float) {
        if fabsf(x) < 0.01, fabsf(y) < 0.01 {
            mqtt.publish(Topic.reset.rawValue, withString: "direction", qos: CocoaMQTTQOS.qos1, retained: false, dup: true)
        } else {
            mqtt.publish(Topic.direction.rawValue, withString: "\(Int(x*100)),\(Int(y*100))", qos: CocoaMQTTQOS.qos0, retained: false, dup: true)
        }
    }
    
    private var directionChange:((Float, Float)->Void)?
    func subscribeDirection(_ change:@escaping ((Float, Float)->Void)) {
        mqtt.subscribe([(Topic.direction.rawValue, .qos0), (Topic.reset.rawValue, .qos1)])
        directionChange = change
    }
    
    func unsubscribeDirection(){
        mqtt.unsubscribe(Topic.direction.rawValue)
        directionChange = nil
    }
}

extension MQTTWrapper : CocoaMQTTDelegate {
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("mqttDidPing")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("mqttDidReceivePong")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("mqttDidDisconnect \(String(describing: err))")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck \(ack.description)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage \(message.string ?? "") \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didReceiveMessage \(message.string ?? "") \(id)")
        guard let topic = Topic(rawValue: message.topic) else { return }
        let msg = message.string ?? ""
        switch topic {
        case .reset:
            switch Reset(rawValue: msg) {
            case .direction:
                directionChange?(0, 0)
            default:
                break
            }
        case .direction:
            let point = msg.split(separator: Character(",")).compactMap { Int(String($0)) }
            if point.count == 2 {
                directionChange?(Float(point[0])/100,Float(point[1])/100)
            }
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        print("didSubscribeTopic \(topics)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didSubscribeTopic \(topic)")
    }
}
