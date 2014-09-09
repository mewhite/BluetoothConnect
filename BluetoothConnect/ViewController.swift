//
// ViewController.swift
// BluetoothConnect
//
// Created by Monisha White on 8/14/14.
// Copyright (c) 2014 Monisha White. All rights reserved.
//
import UIKit
import CoreBluetooth
class ViewController: UIViewController, PostureSenseDriverDelegate {
    var myPostureSenseDriver: PostureSenseDriver? = nil
    @IBOutlet var disengageButton : UIButton!
    @IBOutlet var engageButton : UIButton!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        didChangeStatus(.PoweredOff)
        myPostureSenseDriver = PostureSenseDriver(delegate: self)
    }
    @IBAction func deviceDisengaged(sender : AnyObject) {
        println("device disengaged")
        myPostureSenseDriver?.disengagePostureSense()
    }
    @IBAction func deviceEngaged(sender : AnyObject) {
        println("device engaged")
        myPostureSenseDriver?.engagePostureSense()
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
        case PostureSenseStatus.FindingServices: println("Finding Services") //finding services
        case PostureSenseStatus.DiscoveringCharacteristics: println("Discovering Characteristics") //finding services
        case PostureSenseStatus.SettingUp: println("Setting Up") //finding/setting services/characteristics: real time control, initializing values, etc
        case PostureSenseStatus.Disconnected: println("Disconnected")
        case PostureSenseStatus.Callibrating: println("Callibrating") //setting calibration offsets, etc
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

    func didReceiveBetteryLevel(level: Int)
    {
        // TODO: (YS) update battery view
    }

    func didGetError(error: NSError)
    {
        // TODO: (YS) alert the user
    }
}