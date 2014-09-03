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
    
    var myPostureSenseDriver = PostureSenseDriver()
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        myPostureSenseDriver.delegateCentralManager()
    
    }
    
    func didChangeStatus()
    {
        println("view controller: posture sensor didChangeStatus")
    }
    
    func didReceiveData(data: NSData!)
    {
        println("received data!: \(data)")
    
    }
        
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

