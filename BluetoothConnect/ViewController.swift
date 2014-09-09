//
//  ViewController.swift
//  BluetoothConnect
//
//  Created by Monisha White on 8/14/14.
//  Copyright (c) 2014 Monisha White. All rights reserved.
//

import UIKit

import CoreBluetooth


class ViewController: UIViewController, PostureSenseDriverDelegate {
    
    var myPostureSenseDriver: PostureSenseDriver? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        didChangeStatus(.PoweredOff)
        myPostureSenseDriver = PostureSenseDriver(delegate: self)
    }
    
    func didChangeStatus(status: PostureSenseStatus)
    {
        printStatus(status)
    }
    
    func printStatus(status: PostureSenseStatus)
    {
        switch status
        {
        case PostureSenseStatus.PoweredOff: println("PoweredOff")
        case PostureSenseStatus.Searching: println("Searching") //searching for sensor
        case PostureSenseStatus.Connecting: println("Connecting") //connecting to peripheral/posture sensor
        case PostureSenseStatus.FindingServices: println("Finding Services")  //finding services
        case PostureSenseStatus.DiscoveringCharacteristics: println("Discovering Characteristics")  //finding services

        case PostureSenseStatus.SettingUp: println("Setting Up")  //finding/setting services/characteristics: real time control, initializing values, etc
        case PostureSenseStatus.Disconnected: println("Disconnected")
        case PostureSenseStatus.Callibrating: println("Callibrating")  //setting calibration offsets, etc
        case PostureSenseStatus.Registering: println("Registering") //?
        case PostureSenseStatus.LiveUpdates: println("LiveUpdates") //receiving live data, ready to use, etc
        case PostureSenseStatus.Disengaging: println("Disengaging")
            
        case PostureSenseStatus.Unknown: println("Unknown")
        case PostureSenseStatus.Resetting: println("Resetting")
        case PostureSenseStatus.Unauthorized: println("Unauthorized")
        case PostureSenseStatus.Unsupported: println("Unsupported")
        case PostureSenseStatus.PoweredOn: println("PoweredOn")
            
        }
    }
    
    func didReceiveData(data: NSData!)
    {
        println("Received Data: \(data)")
    }
        
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}

