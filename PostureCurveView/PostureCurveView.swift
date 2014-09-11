//
//  PostureCurveView.swift
//  PostureCurveView
//
//  Created by Monisha White on 9/10/14.
//  Copyright (c) 2014 Monisha White. All rights reserved.
//

import Foundation
import UIKit

/// Sensor angle in radians, 0 is streight, positive is bending forward
typealias FlexAngle = Float

/// Accelerometer 3D data in units of g/256
typealias Acceleration = (x : Int16, y : Int16, z : Int16)

let theSensorsCount = 6
let theAccelerometersCount = 2

/** PostureSense measuers
:angles: array of sensor FlexAngle numbered from bottom to top
:attitudes: array of accelerometer `Acceleration` numbered from bottom to top
*/
struct Posture : Printable
{
    var angles = [FlexAngle] (count: theSensorsCount, repeatedValue: 0)
    var attitudes = [Acceleration] (count: theAccelerometersCount, repeatedValue: (256, 0, 0))
    
    var description: String {
        return "Angles: \(angles)   Attitides: \(attitudes)"
    }
}
// TODO: move Posture to a general project header

class PostureCurveView: UIView
{
    
    required init(coder: NSCoder!)
    {
        super.init(coder: coder)
        setUpView()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setUpView()
    }
    
    override init()
    {
        //super.init(frame: UIScreen.mainScreen().bounds)
        //super.init(frame: UIScreen.mainScreen().bounds)
        super.init(frame: frame)
        setUpView()
    }
    
    
    func setUpView()
    {
        self.backgroundColor = UIColor.blueColor()
    }
    
    func angleChange(angle1: Int, angle2: Int, angle3: Int, angle4: Int, angle5: Int)
    {
        self.drawRect(CGRectMake(CGFloat.convertFromIntegerLiteral(angle1),
            CGFloat.convertFromIntegerLiteral(angle2),
            CGFloat.convertFromIntegerLiteral(angle3),
            CGFloat.convertFromIntegerLiteral(angle4)))
    }
    
    func accelChange()
    {
        
    }
    
    func updatePosture()
    {
        var myPosture = Posture()
    }
    
    
    
    
}