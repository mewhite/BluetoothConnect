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
        println("Driver status: \(status)")
    }
    
    func didReceiveData(posture: Posture)
    {
        println("Live posture: \(posture)")
    }

    func didReceiveBatteryLevel(level: Int)
    {
        // TODO: (YS) update battery view
        println("battery level: \(level)")
    }

    func didGetError(error: NSError)
    {
        // TODO: (YS) alert the user
        println("Error: \(error.domain) - \(error.localizedDescription)")
        if let suggestion = error.localizedRecoverySuggestion {
            println("Solution: " + suggestion)
        }
    }
}