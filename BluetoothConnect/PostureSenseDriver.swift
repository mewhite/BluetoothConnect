//
//  PostureSenseDriver.swift
//  BluetoothConnect
//
//  Created by Monisha White on 9/2/14.
//  Copyright (c) 2014 Monisha White. All rights reserved.
//


import Foundation
import CoreBluetooth


class PostureSenseDriver: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var myCentralManager: CBCentralManager? = nil
    
    var myPeripheral: CBPeripheral? = nil
    
    var myPostureSenseDriverDelegate: PostureSenseDriverDelegate? = nil
    
    func delegateCentralManager()
    {
        myCentralManager = CBCentralManager(delegate:self, queue:dispatch_queue_create(nil, nil))
        myPostureSenseDriverDelegate = ViewController()
    
    }

    
    
    //CENTRAL MANAGER DELEGATE FUNCTIONS
    
    func centralManagerDidUpdateState(central: CBCentralManager!)
    {
        printCentralState(central.state)
        var uuids: [CBUUID] = [CBUUID.UUIDWithString("1800"), CBUUID.UUIDWithString("180A"), CBUUID.UUIDWithString("180F"), CBUUID.UUIDWithString("D6E8F230-1513-11E4-8C21-0800200C9A66")]
        central.scanForPeripheralsWithServices(uuids, options:nil)
        
        myPostureSenseDriverDelegate!.didChangeStatus()
        
    }
    
    func centralManager(central: CBCentralManager!,
        didDiscoverPeripheral peripheral: CBPeripheral!,
        advertisementData: [NSObject : AnyObject]!,
        RSSI: NSNumber!)
    {
        central.stopScan()
        self.myPeripheral = peripheral
        myCentralManager!.connectPeripheral(peripheral, options: nil)
        //myCentralManager!.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: NSString()])
        //TODO: see options documentation and learn how to actually write them.
        //TODO: stop scanning when done / found last peripheral needed, not immediately
    }
    
    func centralManager(central: CBCentralManager!,
        didConnectPeripheral peripheral: CBPeripheral!)
    {
        println("Peripheral connected: \(peripheral.name)")
        peripheral.delegate = self
        //TODO: specify which services to discover - not nil
        peripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager!,
        didFailToConnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        println("Error Connecting: ")
    }
    
    func centralManager(central: CBCentralManager!,
        didDisconnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        println("disconnected peripheral")
    }
    
    //TODO: do we need this function? why this vs ^^ (didDiscoverPeripheral)
    func centralManager(central: CBCentralManager!,
        didRetrievePeripherals peripherals: [AnyObject]!)
    {
        println("didRetrievePeripherals")
        
    }
    
    func centralManager(central: CBCentralManager!,
        didRetrieveConnectedPeripherals peripherals: [AnyObject]!)
    {
        println("did retrieve connected peripherals")
    }
    
    func printCentralState(centralState: CBCentralManagerState)
    {
        var stateName: String
        switch centralState
            {
        case CBCentralManagerState.Unknown: stateName = "unknown"
        case CBCentralManagerState.Resetting: stateName = "resetting"
        case CBCentralManagerState.Unsupported: stateName = "unsupported"
        case CBCentralManagerState.Unauthorized: stateName = "unauthorized"
        case CBCentralManagerState.PoweredOff: stateName = "poweredoff"
        case CBCentralManagerState.PoweredOn: stateName = "poweredon"
        }
        println("Central State = \(stateName)")
    }
    
    
    //PERIPHERAL DELEGATE FUNCTIONS
    
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverServices error: NSError!)
    {
        for service in peripheral.services as [CBService]
        {
            println("Discovered service \(service)")
            //TODO: only look for characteristics of certain services
            println("Discovering characteristics")
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverCharacteristicsForService service: CBService!,
        error: NSError!)
    {
        for characteristic in service.characteristics as [CBCharacteristic]
        {
            //println("CHARACTERISTIC NAME" + (characteristic.UUID.UUIDString))

           // println("CHARACTERISTIC NAME" + (CBUUID.UUIDWithString(characteristic.UUID)).UUIDString)
            if (characteristic.UUID.UUIDString == "D6E91941-1513-11E4-8C21-0800200C9A66")
            {
                println("CHARACTERISTIC NAME" + (characteristic.UUID.UUIDString))
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
            
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        if (error != nil) {
            //println(error)
            //TODO: access error. "localizedDescription" in obj-c
            println("Error changing notification state")
        } else {
            //this should mean it's the characteristic for real time data
            println(characteristic.UUID.UUIDString + "is now notifying")
            //TODO: only change state for the realtime data (last one)
            peripheral.readValueForCharacteristic(characteristic)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        
        println("Updated value for characteristic: \(characteristic) in peripheral \(peripheral.name)")
        let data = ("My Personal Characteristic Data" as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        //TODO: fix error message...unidentifier???
        
        myPostureSenseDriverDelegate?.didReceiveData(data)
        //peripheral.writeValue(data as NSData, forCharacteristic: characteristic, type: CBCharacteristicWriteWithResponse)
        
        
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didWriteValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        NSLog("characteristic value writing")
        //TODO: deal with writing error
    }
    
    /*
    func writeValue(data: NSData!,
    forCharacteristic characteristic: CBCharacteristic!,
    type: CBCharacteristicWriteType)
    {
    let data = (anySwiftString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
    }
    */

    
}

