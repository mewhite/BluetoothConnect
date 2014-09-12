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
        trace("disengage device")
        myPostureSenseDriver?.disengagePostureSense()
    }
    @IBAction func deviceEngaged(sender : AnyObject) {
        trace("engage device")
        myPostureSenseDriver?.engagePostureSense()
    }
    func didChangeStatus(status: PostureSenseStatus)
    {
        trace("Driver status: \(status)")
    }
    
    func didReceiveData(posture: Posture)
    {
        trace("Live posture: \(posture)")
    }

    func didReceiveBatteryLevel(level: Int)
    {
        // TODO: (YS) update battery view
        trace("battery level: \(level)")
    }

    func didGetError(error: NSError)
    {
        // TODO: (YS) alert the user
        trace("Error: \(error.domain) - \(error.localizedDescription)")
        if let suggestion = error.localizedRecoverySuggestion {
            trace("Solution: " + suggestion)
        }
    }

    @IBAction func crash() {
        Analytics.crash()
    }
}
