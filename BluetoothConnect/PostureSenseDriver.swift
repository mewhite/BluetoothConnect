//
// PostureSenseDriver.swift
// BluetoothConnect
//
// Created by Monisha White on 9/2/14.
// Copyright (c) 2014 Monisha White. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit // just for UIDevice in error description

enum PostureSenseStatus : Printable {
    case PoweredOff
    case Searching
    case Connecting
    case SettingUp      // getting services and charecteristics before LiveUpdates
    case Disconnected
    case LiveUpdates
    case Idle           // connected but not receiving LiveUpdates
    case Disengaging    // turning off LiveUpdates

    var description: String {
        switch self {
        case PoweredOff:    return "Bluetooth is off"
        case Searching:     return "Searching Devices"
        case Connecting:    return "Connecting to device"
        case SettingUp:     return "Setting up live updates"
        case Disconnected:  return "Disconnected from device"
        case LiveUpdates:   return "Live update"
        case Idle:          return "Idle"
        case Disengaging:   return "Disengaging"
        }
    }
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

/// Error Domains and Codes
enum ErrorDomain: String
{
    case ConnectionError    = "ConnectionError"
    case SetupError         = "SetupError"
    case RuntimeError       = "RuntimeError"
}
// TODO: (YS) I think we can safely use a single error domain for everything driver-related.

enum ConnectionErrorCodes: Int
{
    case ErrorCodeConnectingToPeripheral        = 1
    case ErrorCodeUnexpectedDisconnect          = 2
    case ErrorCodeDiscoveringServices           = 3
    case ErrorCodeDiscoveringCharacteristics    = 4
    case ErrorCodeUnidentifiedCentralState      = 5
    case ErrorCodeResettingConnection           = 6
    case ErrorCodeBluetoothUnsupported          = 7
    case ErrorCodeBluetoothUnauthorized         = 8
    case ErrorCodeBluetoothPoweredOff           = 9
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
    case ErrorCodeWritingCharacteristicValue    = 4
}

protocol PostureSenseDriverDelegate
{
    func didChangeStatus(status: PostureSenseStatus)
    func didReceiveData(posture: Posture)
    func didReceiveBatteryLevel(level: Int) // TODO: (YS) call this when reading battery level - both on connect, and in regular intervals
    func didGetError(error: NSError)
}

class PostureSenseDriver: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate
{
    var myCentralManager: CBCentralManager? = nil
    var myPeripheral: CBPeripheral? = nil
    var myRealTimeControl: CBCharacteristic? = nil
    var myUnixTimeStamp: CBCharacteristic? = nil

    var myDelegate: PostureSenseDriverDelegate? = nil
    var myDecoder = PostureSenseDecoder()

    var myStatus : PostureSenseStatus = .PoweredOff {
        didSet {
            myDelegate?.didChangeStatus(oldValue)
        }
    }
    
    init(delegate: PostureSenseDriverDelegate)
    {
        myDelegate = delegate
        super.init()
        myCentralManager = CBCentralManager(delegate:self, queue:dispatch_queue_create(nil, nil))
    }
    
    // MARK: - CBCentralManagerDelegate Functions
    
    func centralManagerDidUpdateState(central: CBCentralManager!)
    {
        var nextStatus = PostureSenseStatus.PoweredOff
        var error : NSError? = nil

        switch central.state {
            
        case .PoweredOn:
            nextStatus = .Searching
            central.scanForPeripheralsWithServices(
                [CBUUID.UUIDWithString(ServiceUUID.PostureSensor.toRaw())],
                options:nil)

        case .Resetting, .Unknown: // temporary states
            error = nil

        case .Unsupported:
            error = NSError(
                domain: ErrorDomain.ConnectionError.toRaw(),
                code: ConnectionErrorCodes.ErrorCodeBluetoothUnsupported.toRaw(),
                userInfo: [NSLocalizedDescriptionKey: "The \(UIDevice.currentDevice().model) does not support Bluetooth low energy."]
            )

        case .Unauthorized:
            error = NSError(
                domain: ErrorDomain.ConnectionError.toRaw(),
                code: ConnectionErrorCodes.ErrorCodeBluetoothUnauthorized.toRaw(),
                userInfo: [NSLocalizedDescriptionKey: "The app is not authorized to use Bluetooth low energy",
                    NSLocalizedRecoverySuggestionErrorKey : "Please go to Settings > Privacy to change that."]
            )

        case .PoweredOff:
            error = NSError(
                domain: ErrorDomain.ConnectionError.toRaw(),
                code: ConnectionErrorCodes.ErrorCodeBluetoothPoweredOff.toRaw(),
                userInfo: [NSLocalizedDescriptionKey: "Bluetooth is currently powered off",
                    NSLocalizedRecoverySuggestionErrorKey : "Please go to Settings > Bluetooth to change that."]
            )
        }

        myStatus = nextStatus
        if let err = error {
            myDelegate?.didGetError(err)
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
        myStatus = .Connecting
        
        // TODO: (YS) save the peripheral.identifier if this is the first time, and check against it in future activations - can use NSUserDefaults
    }
    
    func centralManager(central: CBCentralManager!,
        didConnectPeripheral peripheral: CBPeripheral!)
    {
        peripheral.delegate = self
        //TODO: specify which services to discover - not nil?
        // TODO: (YS) in the first time, we need "Device Information" to decide which device to pair with. Afetr that we only need "Posture Sensor"
        // todo: QUESTION (MW) we don't need the Generic Access Profile? Is the local name not the identifier for which posture sensor it is?
        // (YS) Right, the generic access is standard, and we don't need to query it here.
        peripheral.discoverServices(nil)
        myStatus = .SettingUp // WORKAROUND: state not actually changed until next call!
        myStatus = .SettingUp
    }
    
    func centralManager(central: CBCentralManager!,
        didFailToConnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        myDelegate?.didGetError(NSError(domain: ErrorDomain.ConnectionError.toRaw(), code: ConnectionErrorCodes.ErrorCodeConnectingToPeripheral.toRaw(), userInfo: error?.userInfo))
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
        if let err = error {
            myDelegate?.didGetError(error)
            return
        }

        for service in peripheral.services as [CBService] {
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverCharacteristicsForService service: CBService!,
        error: NSError!)
    {
        if let err = error {
            myDelegate?.didGetError(error)
            return
        }

        if let serviceUUID = ServiceUUID.fromRaw(service.UUID.UUIDString)
        {
            switch serviceUUID {
            case .GenericAccessProfile:
                return

            case .DeviceInformation:
                setupDeviceInformation(peripheral, service: service)

            case .PostureSensor:
                setupPostureSensor(peripheral, service: service)
            }
        }
    }
    
    func setupPostureSensor(peripheral: CBPeripheral!, service: CBService!)
    {
        for characteristic in service.characteristics as [CBCharacteristic]
        {
            if let UUID = PostureCharacteristicUUID.fromRaw(characteristic.UUID.UUIDString)
            {
                switch UUID {

                case .UnixTimeStamp: // save for writing into this characteristic
                    myUnixTimeStamp = characteristic

                case .RealTimeControl: // save for writing into this characteristic
                    myRealTimeControl = characteristic

                case .RealTimeData:
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)

                default:
                    peripheral.readValueForCharacteristic(characteristic)
                }
            }
        }
    }

    func setupDeviceInformation(peripheral: CBPeripheral!, service: CBService!)
    {
        for characteristic in service.characteristics as [CBCharacteristic]
        {
            if let UUID = DeviceCharacteristicUUID.fromRaw(characteristic.UUID.UUIDString)
            {
                switch UUID {
                case .SystemID:
                    return
                case .ModelName:
                    return
                case .SerialNumber:
                    return
                case .FirmwareRevision:
                    return
                case .Manufacturer:
                    return
                default: return
                }
                // TODO: (YS) pass the characteristic.data to the decoder and/or the delegate
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        if let err = error {
            myDelegate?.didGetError(error)
            return
        }

        // TODO: (YS) switch(characteristic.service) and check DeviceCharacteristicUUID

        if let UUID = PostureCharacteristicUUID.fromRaw(characteristic.UUID.UUIDString)
        {
            let data = characteristic.value
            switch UUID {
            case .BatteryLevel:
                let level = myDecoder.decodeBatteryLevel(data)
                myDelegate?.didReceiveBatteryLevel(level)

            case .SensorOffsets:
                myDecoder.setSensorOffsets(data)

            case .SensorCoeffs:
                myDecoder.setSensorCoefficients(data)

            case .AccelOffsets:
                myDecoder.setAccelerometerOffsets(data)

            case .RealTimeData:
                let posture = myDecoder.decodeRealTimeData(data)
                myDelegate?.didReceiveData(posture)

            default:
                trace("Received Unexpected Posture Characteristic: \(UUID.toRaw())")
            }
        }

    }
    
    func turnOnRealTimeControl(peripheral: CBPeripheral!)
    {
        // TODO: (YS) ensure peripheral is not nil and is connected
        var onByte = [UInt8] (count: 1, repeatedValue: 1)
        let RealTimeControl_ON = NSData(bytes: &onByte, length: 1)
        peripheral.writeValue(RealTimeControl_ON, forCharacteristic: myRealTimeControl, type: CBCharacteristicWriteType.WithResponse)
        myStatus = .LiveUpdates
    }
    
    //Real Time Control turned off to stop receiving data from sensor.
    //  Notification State remains on, but no data is communicated because real time control is off.
    func turnOffRealTimeControl(peripheral: CBPeripheral!)
    {
        // TODO: (YS) ensure peripheral is not nil and is connected
        var offByte = [UInt8] (count: 1, repeatedValue: 0)
        let RealTimeControl_OFF = NSData(bytes: &offByte, length: 1)
        peripheral.writeValue(RealTimeControl_OFF, forCharacteristic: myRealTimeControl, type: CBCharacteristicWriteType.WithResponse)
   }
    
    //Only purpose of this function is for error checking
    func peripheral(peripheral: CBPeripheral!,
        didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
       if let err = error {
            myDelegate?.didGetError(NSError(
                domain: ErrorDomain.SetupError.toRaw(),
                code: SetupErrorCodes.ErrorCodeUpdatingNotificationState.toRaw(),
                userInfo: err.userInfo))
            trace("Error changing notification state: \(err)")
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didWriteValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        if let err = error { // TODO: (YS) Should probably say "can't subscribe/unsucscribe to live updates" or something like that
            myDelegate?.didGetError(NSError(domain: ErrorDomain.RuntimeError.toRaw(), code: RuntimeErrorCodes.ErrorCodeWritingCharacteristicValue.toRaw(), userInfo: err.userInfo))
        }
        else if myStatus == .Disengaging {
            myStatus = .Idle
        }
    }
    
    func disengagePostureSense()
    {
        myStatus = .Disengaging
        turnOffRealTimeControl(myPeripheral)
    }
    
    func engagePostureSense()
    {
        turnOnRealTimeControl(myPeripheral)
    }
    
    //TODO: make a button to explicitly connect/search, not automatically
    func connectToPostureSensor()
    {
        myCentralManager?.scanForPeripheralsWithServices(
            [CBUUID.UUIDWithString(ServiceUUID.PostureSensor.toRaw())],
            options:nil)
        myStatus = .Searching
    }
    
    func disconnectFromPostureSensor()
    {
        myCentralManager?.cancelPeripheralConnection(myPeripheral)
    }
    
    func centralManager(central: CBCentralManager!,
        didDisconnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        if let err = error {
            myDelegate?.didGetError(NSError(
                domain: ErrorDomain.ConnectionError.toRaw(),
                code: ConnectionErrorCodes.ErrorCodeUnexpectedDisconnect.toRaw(),
                userInfo: err.userInfo))
        }
        else {
            myStatus = .Disconnected
        }
    }
    
}

