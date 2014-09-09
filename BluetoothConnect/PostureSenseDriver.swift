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

/// Bluutooth service UUIDs
enum ServiceUUID : String {
    case GenericAccessProfile   = "1800"
    case DeviceInformation      = "180A"
    case PostureSensor          = "D6E8F230-1513-11E4-8C21-0800200C9A66"
}

/// Characteristic UUIDs for Device Information service
enum DeviceCharacteristicUUID : String {
    case SystemID           = "0x2A23"
    case ModelName          = "0x2A24"
    case SerialNumber       = "0x2A25"
    case FirmwareRevision   = "0x2A26"
    case Manufacturer       = "0x2A29"
}
// TODO: (YS) read these on first time pairing

/// Characteristic UUIDs for Posture Sensor service
enum PostureCharacteristicUUID : String
{
    case BatteryLevel       = "2A19"
    case SensorOffsets      = "D6E8F233-1513-11E4-8C21-0800200C9A66"
    case SensorCoeffs       = "D6E8F234-1513-11E4-8C21-0800200C9A66"
    case AccelOffsets       = "D6E8F235-1513-11E4-8C21-0800200C9A66"
    case UnixTimeStamp      = "D6E91942-1513-11E4-8C21-0800200C9A66"
    case RealTimeControl    = "D6E91940-1513-11E4-8C21-0800200C9A66"
    case RealTimeData       = "D6E91941-1513-11E4-8C21-0800200C9A66"
}

//Characteristics
var batteryLevel: CBCharacteristic? = nil
var sensorOffsets: CBCharacteristic? = nil
var sensorCoeffs: CBCharacteristic? = nil
var accelOffsets: CBCharacteristic? = nil
var unixTimeStamp: CBCharacteristic? = nil
var realTimeControl: CBCharacteristic? = nil
var realTimeData: CBCharacteristic? = nil
// TODO: (YS) no need for this global vars... Instead we need to get the NSData, decode it (using the decoder class), and pass it on to the delegate

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

    // MARK: - CBCentralManagerDelegate Functions
    
    func centralManagerDidUpdateState(central: CBCentralManager!)
    {
        switch central.state {

        case .PoweredOn:
            central.scanForPeripheralsWithServices([CBUUID.UUIDWithString(ServiceUUID.PostureSensor.toRaw())], options:nil)
            myPostureSenseDelegate?.didChangeStatus(.Searching)

        case .Unsupported:
            println("The platform does not support Bluetooth low energy.") // TODO: (YS) alert the delegate

        case .Unauthorized:
            println("The app is not authorized to use Bluetooth low energy") // TODO: (YS) alert the delegate

        case .PoweredOff:
            println("Bluetooth is currently powered off.") // TODO: (YS) alert the delegate

        default:
            myPostureSenseDelegate?.didChangeStatus(.PoweredOff)
        }
    }
    
    func centralManager(central: CBCentralManager!,
        didDiscoverPeripheral peripheral: CBPeripheral!,
        advertisementData: [NSObject : AnyObject]!,
        RSSI: NSNumber!)
    {
        // TODO: (YS) ensure this is a PostureSense device by checking peripheral.name
        central.stopScan()
        self.myPeripheral = peripheral
        // TODO: (YS) maybe should set self as delegate here?  self.myPeripheral.delegate = self
        myCentralManager!.connectPeripheral(peripheral, options: nil)
        myPostureSenseDelegate?.didChangeStatus(.Connecting)

        // TODO: (YS) save the peripheral.identifier if this is the first time, and check against it in future activations - can use NSUserDefaults
    }
    
    func centralManager(central: CBCentralManager!,
        didConnectPeripheral peripheral: CBPeripheral!)
    {
        peripheral.delegate = self
        //TODO: specify which services to discover - not nil?
        // TODO: (YS) in the first time, we need "Device Information". Afetr that we only need "Posture Sensor"
        peripheral.discoverServices(nil)
        myPostureSenseDelegate?.didChangeStatus(.FindingServices) // TODO: (YS) we can probably put this under some generic "getting data" status
    }
    
    func centralManager(central: CBCentralManager!,
        didFailToConnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        println("Error Connecting: ") // TODO: (YS) notify delegate
    }
    
    func centralManager(central: CBCentralManager!,
        didDisconnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        myPostureSenseDelegate?.didChangeStatus(PostureSenseStatus.Disconnected)
    }
    
    //TODO: Implement this functino in case is find many sensors. OR implement didDiscover peripheral to check that it's the correct one.
    // TODO: (YS) if this is the first time (no paired device yet) then we probably want this, since it gets called after all peripherals were discovered, not just the first. (I think...)
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
    
    // MARK: - CBPeripheralDelegate Functions
    
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverServices error: NSError!)
    {
        for service in peripheral.services as [CBService]
        {
            //TODO: only look for characteristics of certain services - "Device Information" and "Posture Sensor"
            peripheral.discoverCharacteristics(nil, forService: service)
            myPostureSenseDelegate?.didChangeStatus(.DiscoveringCharacteristics) // TODO: (YS) we can probably put this under some generic "getting data" status
        }
    }

    func peripheral(peripheral: CBPeripheral!,
        didDiscoverCharacteristicsForService service: CBService!,
        error: NSError!)
    {
        if let serviceUUID = ServiceUUID.fromRaw(service.UUID.UUIDString)
        {
            switch serviceUUID
            {
            case .GenericAccessProfile:
                println()
            case .DeviceInformation:
                println()
            case .PostureSensor:
                storeSensorCharacteristics(peripheral, service: service)
                setUpPostureSense(peripheral)
            default:
                println()
            }
        }
    }
    
    func storeSensorCharacteristics(peripheral: CBPeripheral!, service: CBService!)
    {
        // TODO: (YS) should treat different services seperately
        for characteristic in service.characteristics as [CBCharacteristic]
        {
            if let UUID = PostureCharacteristicUUID.fromRaw(characteristic.UUID.UUIDString)
            {
                switch UUID {
                case .BatteryLevel:
                    println("found battery level")
                    batteryLevel = characteristic
                case .SensorOffsets:
                    println("found sensor offsets")
                    sensorOffsets = characteristic
                case .SensorCoeffs:
                    println("found sensor coeffs")
                    sensorCoeffs = characteristic
                case .AccelOffsets:
                    println("found accel offsets")
                    accelOffsets = characteristic
                case .UnixTimeStamp:
                    println("found time stamp")
                    unixTimeStamp = characteristic
                case .RealTimeControl:
                    println("found real time control")
                    realTimeControl = characteristic
                case .RealTimeData:
                    println("found real time data characteristic")
                    realTimeData = characteristic
                default: println()
                }
                // TODO: (YS) pass the characteristic.data to the decoder and/or the delegate
            }
        }
    }
    
    func setUpPostureSense(peripheral: CBPeripheral!)
    {
        callibratePostureSense(peripheral)
        peripheral.setNotifyValue(true, forCharacteristic: realTimeData) // TODO: (YS) Should this be inside turnOnRealTimeControl()?
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
        let RealTimeControl_ON = NSData(bytes: &onByte, length: 1)
        peripheral.writeValue(RealTimeControl_ON, forCharacteristic: realTimeControl, type: CBCharacteristicWriteType.WithResponse)
    }
    
    func turnOffRealTimeControl(peripheral: CBPeripheral!)
    {
        var offByte = [UInt8] (count: 1, repeatedValue: 0)
        let RealTimeControl_OFF = NSData(bytes: &offByte, length: 1)
        peripheral.writeValue(RealTimeControl_OFF, forCharacteristic: realTimeControl, type: CBCharacteristicWriteType.WithResponse)
        println("turned off real time control")
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        if let err = error {
            //println(error)
            //TODO: access error. "localizedDescription" in obj-c
            println("Error changing notification state: \(err)")
            // TODO: (YS) notify delegate that there's a problem
        } else {
            //this should mean it's the characteristic for real time data
            //TODO: only change state for the realtime data (last one)
            //peripheral.readValueForCharacteristic(characteristic)
            // TODO: (YS) notify delegate that we are receiving RT data at last
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        if let UUID = PostureCharacteristicUUID.fromRaw(characteristic.UUID.UUIDString)
        {
            switch UUID {
            case .BatteryLevel:
                var batteryLevelString: String = NSString(data: characteristic.value, encoding: NSUTF8StringEncoding)
                println("battery level decoded data: " + batteryLevelString)
                println("battery level as NSData: \(characteristic.value) ")
                var decodedInteger: Int? = nil
                (characteristic.value).getBytes(&decodedInteger, length: 4)
                println("battery level bytes into integer: \(decodedInteger)")
            case .SensorOffsets: println()
            case .SensorCoeffs: println()
            case .AccelOffsets: println()
            case .UnixTimeStamp: println()
            case .RealTimeControl:
                println()
            case .RealTimeData:
                myPostureSenseDelegate?.didReceiveData(characteristic.value)
            default: println()
            }
            // TODO: (YS) after integrations with decoder - send vals to decoder and/or delegate
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

}

