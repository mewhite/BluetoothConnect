//
// PostureSenseDriver.swift
// BluetoothConnect
//
// Created by Monisha White on 9/2/14.
// Copyright (c) 2014 Monisha White. All rights reserved.
//

import Foundation
import CoreBluetooth

enum PostureSenseStatus {
    case PoweredOff
    case Searching
    case Connecting
    case FindingServices
    case DiscoveringCharacteristics
    case SettingUp
    case Disconnected
    case Callibrating
    case Registering
    case LiveUpdates
    case Disengaging
    
    case Unknown
    case Resetting
    case Unauthorized
    case Unsupported
    case PoweredOn
}

//Service UUID Constants
let GENERIC_ACCESS_PROFILE = CBUUID.UUIDWithString("1800")
let DEVICE_INFORMATION = CBUUID.UUIDWithString("180A")
let POSTURE_SENSOR = CBUUID.UUIDWithString("D6E8F230-1513-11E4-8C21-0800200C9A66")
let UUIDS: [CBUUID] = [GENERIC_ACCESS_PROFILE, DEVICE_INFORMATION, POSTURE_SENSOR]

//Characteristic UUID Constants
enum CharacteristicUUID: String
{
    case BATTERY_LEVEL = "2A19"
    case SENSOR_OFFSETS = "D6E8F233-1513-11E4-8C21-0800200C9A66"
    case SENSOR_COEFFS = "D6E8F234-1513-11E4-8C21-0800200C9A66"
    case ACCEL_OFFSETS = "D6E8F235-1513-11E4-8C21-0800200C9A66"
    case UNIX_TIME_STAMP = "D6E91942-1513-11E4-8C21-0800200C9A66"
    case REAL_TIME_CONTROL = "D6E91940-1513-11E4-8C21-0800200C9A66"
    case REAL_TIME_DATA = "D6E91941-1513-11E4-8C21-0800200C9A66"
}

//Constants

//Characteristics
var batteryLevel: CBCharacteristic? = nil
var sensorOffsets: CBCharacteristic? = nil
var sensorCoeffs: CBCharacteristic? = nil
var accelOffsets: CBCharacteristic? = nil
var unixTimeStamp: CBCharacteristic? = nil
var realTimeControl: CBCharacteristic? = nil
var realTimeData: CBCharacteristic? = nil

protocol PostureSenseDriverDelegate
{
    func didChangeStatus(status: PostureSenseStatus)
    func didReceiveData(data: NSData!)
}

class PostureSenseDriver: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var myCentralManager: CBCentralManager? = nil
    var myPeripheral: CBPeripheral? = nil
    var myPostureSenseDelegate: PostureSenseDriverDelegate? = nil
    init(delegate: PostureSenseDriverDelegate)
    {
        myPostureSenseDelegate = delegate
        super.init()
        myCentralManager = CBCentralManager(delegate:self, queue:dispatch_queue_create(nil, nil))
    }
    //CENTRAL MANAGER DELEGATE FUNCTIONS
    func centralManagerDidUpdateState(central: CBCentralManager!)
    {
        myPostureSenseDelegate?.didChangeStatus(.PoweredOn)
        //TODO: check which state its in and scan/act accordingly
        central.scanForPeripheralsWithServices(UUIDS, options:nil)
        myPostureSenseDelegate?.didChangeStatus(.Searching)
    }
    
    func centralManager(central: CBCentralManager!,
        didDiscoverPeripheral peripheral: CBPeripheral!,
        advertisementData: [NSObject : AnyObject]!,
        RSSI: NSNumber!)
    {
        central.stopScan()
        self.myPeripheral = peripheral
        myCentralManager!.connectPeripheral(peripheral, options: nil)
        //TODO: change options for connecting?
        myPostureSenseDelegate?.didChangeStatus(.Connecting)
        //TODO: stop scanning when done - if user selects posture sensor, it should stop scan - until then, it finds all sensors around - user can select which to connect to
    }
    
    func centralManager(central: CBCentralManager!,
        didConnectPeripheral peripheral: CBPeripheral!)
    {
        peripheral.delegate = self
        //TODO: specify which services to discover - not nil?
        peripheral.discoverServices(nil)
        myPostureSenseDelegate?.didChangeStatus(.FindingServices)
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
        myPostureSenseDelegate?.didChangeStatus(PostureSenseStatus.Disconnected)
    }
    
    //TODO: Implement this functino in case is find many sensors. OR implement didDiscover peripheral to check that it's the correct one.
    func centralManager(central: CBCentralManager!,
        didRetrievePeripherals peripherals: [AnyObject]!)
    {
        //println("didRetrievePeripherals")
    }
    
    func centralManager(central: CBCentralManager!,
        didRetrieveConnectedPeripherals peripherals: [AnyObject]!)
    {
        //println("did retrieve connected peripherals")
    }
    
    func printCentralState(centralState: CBCentralManagerState)
    {
        var stateName: String
        var status: PostureSenseStatus
        switch centralState
        {
        case CBCentralManagerState.Unknown: stateName = "unknown"; status = .Unknown
        case CBCentralManagerState.Resetting: stateName = "resetting"; status = .Resetting
        case CBCentralManagerState.Unsupported: stateName = "unsupported"; status = .Unsupported
        case CBCentralManagerState.Unauthorized: stateName = "unauthorized"; status = .Unauthorized
        case CBCentralManagerState.PoweredOff: stateName = "poweredoff"; status = .PoweredOff
        case CBCentralManagerState.PoweredOn: stateName = "poweredon"; status = .PoweredOn
        }
        //TODO: for testing / potential debugging purposes, should eventually take out. don't know when it updates to these states..
        println("Central State, printed from PostureSenseDriver = \(stateName)")
        myPostureSenseDelegate?.didChangeStatus(status)
    }
    
    //PERIPHERAL DELEGATE FUNCTIONS
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverServices error: NSError!)
    {
        for service in peripheral.services as [CBService]
        {
            peripheral.discoverCharacteristics(nil, forService: service)
            myPostureSenseDelegate?.didChangeStatus(.DiscoveringCharacteristics)
        }
    }
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverCharacteristicsForService service: CBService!,
        error: NSError!)
    {
        if let serviceUUID = service.UUID
        {
            switch serviceUUID
            {
            case GENERIC_ACCESS_PROFILE:
                println()
            case DEVICE_INFORMATION:
                println()
            case POSTURE_SENSOR:
                storeSensorCharacteristics(peripheral, service: service)
                setUpPostureSense(peripheral)
            default:
                println()
            }
        }
    }
    
    func storeSensorCharacteristics(peripheral: CBPeripheral!, service: CBService!)
    {
        for characteristic in service.characteristics as [CBCharacteristic]
        {
            if let UUID = CharacteristicUUID.fromRaw(characteristic.UUID.UUIDString)
            {
                switch UUID
                    {
                case CharacteristicUUID.BATTERY_LEVEL:
                    println("found battery level")
                    batteryLevel = characteristic
                case .SENSOR_OFFSETS:
                    println("found sensor offsets")
                    sensorOffsets = characteristic
                case .SENSOR_COEFFS:
                    println("found sensor coeffs")
                    sensorCoeffs = characteristic
                case .ACCEL_OFFSETS:
                    println("found accel offsets")
                    accelOffsets = characteristic
                case .UNIX_TIME_STAMP:
                    println("found time stamp")
                    unixTimeStamp = characteristic
                case .REAL_TIME_CONTROL:
                    println("found real time control")
                    realTimeControl = characteristic
                case .REAL_TIME_DATA:
                    println("found real time data characteristic")
                    realTimeData = characteristic
                default: println()
                }
            }
        }
    }
    
    func setUpPostureSense(peripheral: CBPeripheral!)
    {
        callibratePostureSense(peripheral)
        peripheral.setNotifyValue(true, forCharacteristic: realTimeData)
        turnOnRealTimeControl(peripheral)
    }
    
    func callibratePostureSense(peripheral: CBPeripheral!)
    {
        peripheral.readValueForCharacteristic(sensorCoeffs)
        peripheral.readValueForCharacteristic(sensorOffsets)
        peripheral.readValueForCharacteristic(accelOffsets)
    }

    func turnOnRealTimeControl(peripheral: CBPeripheral!)
    {
        var onByte = [UInt8] (count: 1, repeatedValue: 1)
        let REAL_TIME_CONTROL_ON = NSData(bytes: &onByte, length: 1)
        peripheral.writeValue(REAL_TIME_CONTROL_ON, forCharacteristic: realTimeControl, type: CBCharacteristicWriteType.WithResponse)
    }
    
    func turnOffRealTimeControl(peripheral: CBPeripheral!)
    {
        var offByte = [UInt8] (count: 1, repeatedValue: 0)
        let REAL_TIME_CONTROL_OFF = NSData(bytes: &offByte, length: 1)
        peripheral.writeValue(REAL_TIME_CONTROL_OFF, forCharacteristic: realTimeControl, type: CBCharacteristicWriteType.WithResponse)
        println("turned off real time control")
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        if (error) {
            //println(error)
            //TODO: access error. "localizedDescription" in obj-c
            println("Error changing notification state")
        } else {
            //this should mean it's the characteristic for real time data
            //TODO: only change state for the realtime data (last one)
            //peripheral.readValueForCharacteristic(characteristic)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        if let UUID = CharacteristicUUID.fromRaw(characteristic.UUID.UUIDString)
        {
            switch UUID
                {
            case .BATTERY_LEVEL:
                var batteryLevelString: String = NSString(data: characteristic.value, encoding: NSUTF8StringEncoding)
                println("battery level decoded data: " + batteryLevelString)
                println("battery level as NSData: \(characteristic.value) ")
                var decodedInteger: Int? = nil
                (characteristic.value).getBytes(&decodedInteger, length: 4)
                println("battery level bytes into integer: \(decodedInteger)")
                //&decodedInteger length:sizeof(decodedInteger)];
            case .SENSOR_OFFSETS: println()
            case .SENSOR_COEFFS: println()
            case .ACCEL_OFFSETS: println()
            case .UNIX_TIME_STAMP: println()
            case .REAL_TIME_CONTROL:
                println()
            case .REAL_TIME_DATA:
                myPostureSenseDelegate?.didReceiveData(characteristic.value)
            default: println()
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didWriteValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        //NSLog("characteristic value writing")
        //TODO: deal with writing error
    }
    
    func disengagePostureSense()
    {
        println("disengaged")
        turnOffRealTimeControl(myPeripheral)
    }
    func engagePostureSense()
    {
        println("engaged")
        turnOnRealTimeControl(myPeripheral)
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

