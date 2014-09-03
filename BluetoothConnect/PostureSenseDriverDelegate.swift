//
//  PostureSenseDriverDelegate.swift
//  BluetoothConnect
//
//  Created by Monisha White on 9/2/14.
//  Copyright (c) 2014 Monisha White. All rights reserved.
//

import Foundation

protocol PostureSenseDriverDelegate
{
    func didChangeStatus()
    func didReceiveData(data: NSData!)
}