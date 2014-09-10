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
        println("disengage device")
        myPostureSenseDriver?.disengagePostureSense()
    }
    @IBAction func deviceEngaged(sender : AnyObject) {
        println("engage device")
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
            case PostureSenseStatus.SettingUp: println("Setting Up") //finding/setting services/characteristics: real time control, initializing values, etc
            case PostureSenseStatus.Disconnected: println("Disconnected")
            case PostureSenseStatus.LiveUpdates: println("LiveUpdates") //receiving live data, ready to use, etc
            case PostureSenseStatus.Disengaging: println("Disengaging")
            case PostureSenseStatus.Idle: println("Idle")
        }
    }
    func didReceiveData(data: NSData!)
    {
        println("Received Data: \(data)")
    }

    func didReceiveBatteryLevel(level: Int)
    {
        // TODO: (YS) update battery view
    }

    func didGetError(error: NSError)
    {
        if let errorDomain = ErrorDomain.fromRaw(error.domain)
        {
            switch errorDomain
            {
            case ErrorDomain.ConnectionError:
                println(errorDomain.toRaw())
                
            case ErrorDomain.SetupError:
                println(errorDomain.toRaw())
                
            case ErrorDomain.RuntimeError:
                println(errorDomain.toRaw())
            }
        }
        // TODO: (YS) alert the user
    }
}