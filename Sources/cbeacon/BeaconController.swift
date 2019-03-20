//
//  BeaconController.swift
//  cbeacon
//
//  Created by ohya on 2018/09/03.
//  Copyright © 2018年 ohya. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

// Wait time until Bluetooth turns on
let WAIT_BT_TIME = 10.0

enum BleEvent {
    case power_on, power_off, advertising_ok, advertising_fail, error
}

@available(OSX 10.12, *)
class BeaconController: NSObject, CBPeripheralManagerDelegate {
    enum State {
        case none, setup, ready, advertising, done, fail
    }
    var state = State.none
    let runLoop = RunLoop.current
    var manager: CBPeripheralManager!
    let beacon: BeaconData
    let duration: TimeInterval

    init(beacon:BeaconData, duration:UInt16) {
        self.beacon = beacon
        self.duration = TimeInterval(duration)
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - State & Task Control
    
    func exec() {
        setState(newState:.setup)
        
        Timer.scheduledTimer(withTimeInterval: WAIT_BT_TIME, repeats: false, block: { (timer) in
            if (self.state == .setup) {
                self.setState(newState:.fail)
                // RunLoop 停止
                CFRunLoopStop(self.runLoop.getCFRunLoop())
            }
        })

        while true {
            if !runLoop.run(mode: RunLoop.Mode.default, before: Date.distantFuture) {
                break
            }
            if (state == .done || state == .fail) {
                break
            }
        }
    }
    
    private func setState(newState:State) {
        state = newState
    }
    
    func receiveEvent(event: BleEvent) {
        switch state {
        case .none:
            return
        case .setup:
            if (event == .power_on) {
                // print("Bluetooth turns ON.")
                setState(newState:.ready)
                startAdvertising(beaconData: beacon)
                return
            }
            if (event == .power_off) {
                print("Please turn bluetooth ON.")
                return
            }
        case .ready:
            if (event == .advertising_ok) {
                print("advertising...", terminator: "")
                fflush(stdout)
                setState(newState:.advertising)
                Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { (timer) in
                    self.stopAdvertising()
                    print("stop")
                    self.setState(newState:.done)
                })
                return
            }
        case .advertising:
            if (event == .power_off) {
                print("Bluetooth turned OFF.")
                setState(newState:.fail)
                return
            }
        default:
            return
        }
    }
    
    // MARK: - Blutooth Control
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            receiveEvent(event: .power_on)
        case .poweredOff:
            receiveEvent(event: .power_off)
        case .unauthorized, .resetting, .unsupported, .unknown:
            receiveEvent(event: .error)
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if error == nil {
            receiveEvent(event: .advertising_ok)
        } else {
            receiveEvent(event: .advertising_fail)
        }
    }
    
    func startAdvertising(beaconData: BeaconData) {
        manager.startAdvertising(beaconData.data())
    }
    
    func stopAdvertising() {
        if manager.isAdvertising {
            manager.stopAdvertising()
        }
    }
}

// MARK: -

class BeaconData: NSObject {
    
    let dataToBeAdvertised: [String: Any]
    
    init(uuid:UUID, major:UInt16, minor: UInt16, measuredPower: Int8) {
        var buffer = [CUnsignedChar](repeating: 0, count: 21)
        (uuid as NSUUID).getBytes(&buffer)
        buffer[16] = CUnsignedChar(major >> 8)
        buffer[17] = CUnsignedChar(major & 255)
        buffer[18] = CUnsignedChar(minor >> 8)
        buffer[19] = CUnsignedChar(minor & 255)
        buffer[20] = CUnsignedChar(bitPattern: measuredPower)
        let data = NSData(bytes: buffer, length: buffer.count)
        self.dataToBeAdvertised = ["kCBAdvDataAppleBeaconKey": data]
        super.init()
    }
    
    func data() -> [String: Any] {
        return dataToBeAdvertised
    }
}
