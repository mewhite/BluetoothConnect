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
    case SettingUp
    case Disconnected
    case Registering        //This will be relevant when making accounts, etc
    case LiveUpdates
    case Idle
    case Disengaging
    
    case Unknown
    case Resetting
    case Unauthorized
    case Unsupported
    case PoweredOn
}

/// Bluutooth service UUIDs
enum ServiceUUID : String
{
    case GenericAccessProfile   = "1800"
    case DeviceInformation      = "180A"
    case PostureSensor          = "D6E8F230-1513-11E4-8C21-0800200C9A66"
}

/// Characteristic UUIDs for Device Information service
enum DeviceCharacteristicUUID : String
{
    case SystemID           = "0x2A23"
    case ModelName          = "0x2A24"
    case SerialNumber       = "0x2A25"
    case FirmwareRevision   = "0x2A26"
    case Manufacturer       = "0x2A29"
}
// TODO: (YS) read these on first time pairing

///Error Domains and Codes
enum ErrorDomain: String
{
    case ConnectionError    = "ConnectionError"
    case SetupError         = "SetupError"
    case RuntimeError       = "RuntimeError"
    
}
enum ConnectionErrorCodes: Int
{
    case ErrorCodeConnectingToPeripheral        = 1
    case ErrorCodeUnexpectedDisconnect          = 2
    case ErrorCodeDiscoveringServices           = 3
    case ErrorCodeDiscoveringCharacteristics    = 4
    
    
}
enum SetupErrorCodes: Int
{
    case ErrorCodeUpdatingNotificationState     = 1
    

}
enum RuntimeErrorCodes: Int
{
    case ErrorCodeReceivingRealTimeData         = 1
    case ErrorCodeUpdatingCharacteristicValue   = 2
    case ErrorCodeSettingRealTimeControl        = 3
}

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
// TODO: (YS) no need for these global vars... Instead we need to get the NSData, decode it (using the decoder class), and pass it on to the delegate
// TODO: QUESTION: (MW) Oh that makes sense for the sensor offsets/coeffs, etc, but what about the battery level, realTimecontrol (and TimeStamp?? Are we even using the timestamp yet?). How do we write to / read values of characteristics at will/as desired after initial setup. for realtime data we'll be updated when it changed, but for the other changing values?

protocol PostureSenseDriverDelegate
{
    func didChangeStatus(status: PostureSenseStatus)
    func didReceiveData(data: NSData!)
    func didReceiveBatteryLevel(level: Int) // TODO: (YS) call this when reading battery level - both on connect, and in regular intervals
    func didGetError(error: NSError) // TODO: (YS) call this on error and some state changes. Delegate should alert the user.
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
            central.scanForPeripheralsWithServices(
                [CBUUID.UUIDWithString(ServiceUUID.PostureSensor.toRaw()),
                CBUUID.UUIDWithString(ServiceUUID.DeviceInformation.toRaw()),
                CBUUID.UUIDWithString(ServiceUUID.GenericAccessProfile.toRaw())],
                options:nil)
            myPostureSenseDelegate?.didChangeStatus(.Searching)
        case .Unsupported:
            println("The platform does not support Bluetooth low energy.") // TODO: (YS) alert the delegate
            
        case .Unauthorized:
            println("The app is not authorized to use Bluetooth low energy") // TODO: (YS) alert the delegate
            
        case .PoweredOff:
            println("Bluetooth is currently powered off.") // TODO: (YS) alert the delegate
            //TODO: state poweredOff
            
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
        // TODO: (YS) in the first time, we need "Device Information" to decide which device to pair with. Afetr that we only need "Posture Sensor"
        // todo: QUESTION (MW) we don't need the Generic Access Profile? Is the local name not the identifier for which posture sensor it is?
        peripheral.discoverServices(nil)
        println("Finding Services")
        myPostureSenseDelegate?.didChangeStatus(.SettingUp)
    }
    
    func centralManager(central: CBCentralManager!,
        didFailToConnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        myPostureSenseDelegate?.didGetError(NSError(domain: ErrorDomain.ConnectionError.toRaw(), code: ConnectionErrorCodes.ErrorCodeConnectingToPeripheral.toRaw(), userInfo: nil))
    }
    
    func centralManager(central: CBCentralManager!,
        didDisconnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        myPostureSenseDelegate?.didChangeStatus(PostureSenseStatus.Disconnected)
        myPostureSenseDelegate?.didGetError(NSError(domain: ErrorDomain.ConnectionError.toRaw(), code: ConnectionErrorCodes.ErrorCodeUnexpectedDisconnect.toRaw(), userInfo: nil))
    }
    
    //TODO: Implement this function in case it find many sensors. OR implement didDiscover peripheral to check that it's the correct one.
    // TODO: (YS) if this is the first time (no paired device yet) then we probably want this, since it gets called after all peripherals were discovered, not just the first. (I think...)
    func centralManager(central: CBCentralManager!,
        didRetrievePeripherals peripherals: [AnyObject]!)
    {
        //println("didRetrievePeripherals")
    }
    
    // MARK: - CBPeripheralDelegate Functions
    
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverServices error: NSError!)
    {
        for service in peripheral.services as [CBService]
        {
            peripheral.discoverCharacteristics(nil, forService: service)
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
                storePostureSensorCharacteristics(peripheral, service: service)
                setUpPostureSense(peripheral)
            default:
                println()
            }
        }
    }
    
    func storePostureSensorCharacteristics(peripheral: CBPeripheral!, service: CBService!)
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
                    peripheral.readValueForCharacteristic(characteristic)
                case .SensorOffsets:
                    println("found sensor offsets")
                    peripheral.readValueForCharacteristic(characteristic)
                    //TODO: pass data to decoder/delegate
                    sensorOffsets = characteristic
                case .SensorCoeffs:
                    println("found sensor coeffs")
                    peripheral.readValueForCharacteristic(characteristic)
                    //TODO: pass to decoder/delegate
                    sensorCoeffs = characteristic
                case .AccelOffsets:
                    println("found accel offsets")
                    peripheral.readValueForCharacteristic(characteristic)
                    //TODO: pass data to decoder/delegate
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

    func storeDeviceInformationCharacteristics(peripheral: CBPeripheral!, service: CBService!)
    {
        // TODO: (YS) should treat different services seperately
        for characteristic in service.characteristics as [CBCharacteristic]
        {
            if let UUID = DeviceCharacteristicUUID.fromRaw(characteristic.UUID.UUIDString)
            {
                switch UUID {
                case .SystemID:
                    println()
                case .ModelName:
                    println()
                case .SerialNumber:
                    println()
                case .FirmwareRevision:
                    println()
                case .Manufacturer:
                    println()
                default: println()
                }
                // TODO: (YS) pass the characteristic.data to the decoder and/or the delegate
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
        let RealTimeControl_ON = NSData(bytes: &onByte, length: 1)
        peripheral.writeValue(RealTimeControl_ON, forCharacteristic: realTimeControl, type: CBCharacteristicWriteType.WithResponse)
        myPostureSenseDelegate?.didChangeStatus(.LiveUpdates)
    }
    
    //Real Time Control turned off to stop receiving data from sensor.
    //  Notification State remains on, but no data is communicated because real time control is off.
    func turnOffRealTimeControl(peripheral: CBPeripheral!)
    {
        var offByte = [UInt8] (count: 1, repeatedValue: 0)
        let RealTimeControl_OFF = NSData(bytes: &offByte, length: 1)
        peripheral.writeValue(RealTimeControl_OFF, forCharacteristic: realTimeControl, type: CBCharacteristicWriteType.WithResponse)
        myPostureSenseDelegate?.didChangeStatus(.Idle)
    }
    
    //Only purpose of this function is for error checking
    func peripheral(peripheral: CBPeripheral!,
        didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
       if let err = error {
            myPostureSenseDelegate?.didGetError(NSError(
                domain: ErrorDomain.SetupError.toRaw(),
                code: SetupErrorCodes.ErrorCodeUpdatingNotificationState.toRaw(),
                userInfo: nil))
            println("Error changing notification state: \(err)")
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        if let UUID = PostureCharacteristicUUID.fromRaw(characteristic.UUID.UUIDString)
        {
            switch UUID {
            case .BatteryLevel: println()
            case .SensorOffsets: println()
            case .SensorCoeffs: println()
            case .AccelOffsets: println()
            case .UnixTimeStamp: println()
            case .RealTimeControl: println()
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
        myPostureSenseDelegate?.didChangeStatus(.Disengaging)
        println("disengaging")
        turnOffRealTimeControl(myPeripheral)
    }
    
    func engagePostureSense()
    {
        println("engaging")
        turnOnRealTimeControl(myPeripheral)
    }
    
}

