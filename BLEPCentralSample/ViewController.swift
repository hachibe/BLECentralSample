//
//  ViewController.swift
//  BLEPCentralSample
//
//  Created by Hachibe on 2017/11/30.
//  Copyright © 2017年 Masanori. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    let serviceUUID = CBUUID(string: "0000")
//    let characteristicUUID = CBUUID(string: "0001")
    
    @IBOutlet weak var logTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @IBAction func startScanPeripheralsButtonDidTouched() {
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    @IBAction func stopScanPeripheralsButtonDidTouched() {
        centralManager.stopScan()
    }
    
    @IBAction func cancelPeripheralButtonDidTouched() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    @IBAction func deleteLogButtonTouched() {
        logTextView.text = ""
    }
    
    private func appendLog(_ text: String) {
        print(text)
        logTextView.isScrollEnabled = false
        logTextView.text.append(text + "\n")
        scrollToButtom()
    }
    
    private func appendSubLog(_ text: String) {
        appendLog("  " + text)
    }
    private func scrollToButtom() {
        logTextView.selectedRange = NSRange(location: logTextView.text.count, length: 0)
        logTextView.isScrollEnabled = true
        
        let scrollY = logTextView.contentSize.height - logTextView.bounds.height
        let scrollPoint = CGPoint(x: 0, y: scrollY > 0 ? scrollY : 0)
        logTextView.setContentOffset(scrollPoint, animated: true)
    }
}

// MARK: - CBCentralManagerDelegate
extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        appendLog("Central UpdateState: \(central.state)\n")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        appendLog("Central Discover")
        guard let uuidArray = advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID],
            let uuid = uuidArray.first else {
                appendSubLog("no UUID\n")
                return
        }
        appendSubLog("UUID: \(uuid)")
        if uuid == serviceUUID {
            // Peripheralに接続
            connectedPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
            appendSubLog("connect\n")
        } else {
            appendLog("\n")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        appendLog("Central Connect\n")
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        appendLog("Central FailToConnect")
        appendSubLog("error: \(String(describing: error))\n")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        appendLog("Central Disconnect")
        appendSubLog("error: \(String(describing: error))\n")
    }
}

// MARK: - CBPeripheralDelegate
extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        appendLog("Peripheral DiscoverServices")
        guard error == nil else {
            appendSubLog("error: \(String(describing: error))\n")
            return
        }
        guard let services = peripheral.services else {
            appendSubLog("no services\n")
            return
        }
        for service in services {
            appendSubLog("service: \(service)")
            peripheral.discoverCharacteristics([serviceUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        appendLog("Peripheral DiscoverIncludedServices")
        appendSubLog("service: \(service)")
        guard error == nil else {
            appendSubLog("error: \(String(describing: error))\n")
            return
        }
        guard let characteristics = service.characteristics else {
            appendSubLog("no characteristics\n")
            return
        }
        for characteristic in characteristics {
            appendSubLog("properties: \(characteristic.properties)")
            peripheral.readValue(for: characteristic)
        }
        appendLog("\n")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        appendLog("Peripheral DiscoverCharacteristics")
        appendSubLog("service: \(service)")
        guard error == nil else {
            appendSubLog("error: \(String(describing: error))\n")
            return
        }
        appendSubLog("success\n")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        appendLog("Peripheral UpdateValue")
        guard error == nil else {
            appendSubLog(" error: \(String(describing: error))\n")
            return
        }
        appendSubLog("service.uuid: \(characteristic.service.uuid)")
        appendSubLog("characteristic.uuid: \(characteristic.uuid)")
        appendSubLog("value: \(String(describing: characteristic.value))\n")
    }
}
