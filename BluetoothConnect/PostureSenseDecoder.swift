//
//  PostureSenseDecoder.swift
//
//  Created by Yonat Sharon on 3/9/14.
//  Copyright (c) 2014 Yonat Sharon. All rights reserved.
//

import Foundation

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
struct Posture
{
    var angles = [FlexAngle] (count: theSensorsCount, repeatedValue: 0)
    var attitudes = [Acceleration] (count: theAccelerometersCount, repeatedValue: (256, 0, 0))
}

extension Array {
    /// Make the array have n elements, by either deleting extra elements at the end,
    /// or appending new elements with filler.
    mutating func setCount(n : Int, filler : T)
    {
        while n < count {
            removeLast()
        }
        while n > count {
            append(filler)
        }
    }
}

///  Translates PostureSense data to sensor angles and accelerometer values
///  according to the the Sensor Interface Specification V2 Aug 27 2014
class PostureSenseDecoder
{
    /// :raw12bytes: 6 pairs of bytes, each representing one sensor offset as 16-bit signed integer
    func setSensorOffsets(raw12bytes : NSData)
    {
        let filler = sensorOffsets.last ?? 0
        sensorOffsets = data2vals(raw12bytes)
        sensorOffsets.setCount(theSensorsCount, filler: filler)
    }

    /// :raw12bytes: 6 pairs of bytes, each representing one sensor coefficient as 16-bit signed integer
    func setSensorCoefficients(raw12bytes : NSData)
    {
        let filler = sensorCoefficients.last ?? 0
        sensorCoefficients = data2vals(raw12bytes)
        sensorCoefficients.setCount(theSensorsCount, filler: filler)
    }

    /** :raw12bytes: 6 pairs of bytes, each representing one 16-bit signed integer:
        the first 3 are the xyz offsets for the bottom accelerometer,
        and the last 3 are the xyz offsets for the top accelerometer. */
    func setAccelerometerOffsets(raw12bytes : NSData)
    {
        let filler = accelerometerOffsets.last ?? 0
        accelerometerOffsets = data2vals(raw12bytes)
        accelerometerOffsets.setCount(theAccelerometersCount * 3, filler: filler)
    }

    /// :returns: battery level as a percent
    func decodeBatteryLevel(raw1Byte : NSData) -> Int
    {
        if raw1Byte.length != 1 {
            println("Warning: Battery level is \(raw1Byte.length) bytes instead of 1")
            return 0
        }
        var level = [UInt8](count: 1, repeatedValue: 0)
        raw1Byte.getBytes(&level, length: 1)
        return Int(level[0])
    }

    /// :raw20bytes: first 12 bytes are sensor values, last 8 bytes are 2 accelerometer condensed words
    func decodeRealTimeData(raw20bytes: NSData) -> Posture
    {
        // sensor values
        let sensorDataLength = theSensorsCount * 2
        var sensorValues = data2vals( NSData(bytes: raw20bytes.bytes, length: max(sensorDataLength, raw20bytes.length)) )
        sensorValues.setCount(theSensorsCount, filler: 0)

        // accelerometer values
        var accelValues = [Acceleration]()
        var accelWord = [UInt8](count: 4, repeatedValue: 0)
        for i in 0 ..< theAccelerometersCount {
            let location = sensorDataLength + 4*i
            if location > raw20bytes.length - 4 {
                println("Warning: RT data is only \(raw20bytes.length) bytes instead of 20")
                break
            }
            raw20bytes.getBytes(&accelWord, range: NSRange(location: location, length: 4))
            let a : Acceleration = decodeAccelWord(accelWord)
            accelValues.append(a)
        }
        accelValues.setCount(theAccelerometersCount, filler: (0, 0, 0))

        // normalize values according to calibration
        var ret = Posture()
        for var i = 0; i < theSensorsCount; ++i {
            ret.angles[i] = FlexAngle(sensorValues[i] - sensorOffsets[i]) / FlexAngle(sensorCoefficients[i])
        }
        for var i = 0; i < theAccelerometersCount; ++i {
            ret.attitudes[i] = accelValues[i]
            ret.attitudes[i].x -= accelerometerOffsets[3*i]
            ret.attitudes[i].y -= accelerometerOffsets[3*i + 1]
            ret.attitudes[i].z -= accelerometerOffsets[3*i + 2]
        }

        return ret
    }

// MARK: - Private

    var sensorOffsets = [Int16](count: theSensorsCount, repeatedValue: 2048)
    var sensorCoefficients = [Int16](count: theSensorsCount, repeatedValue: -767)
    var accelerometerOffsets = [Int16](count: theAccelerometersCount * 3, repeatedValue: 0)

    /// :data: a buffer of 2-byte signed integers, little-endian encoded.
    func data2vals(data: NSData) -> [Int16]
    {
        var vals = [UInt16](count: data.length/2, repeatedValue: 0)
        data.getBytes(&vals, length: 2*vals.count)

        var ret = [Int16](count: vals.count, repeatedValue: 0)
        let signBit : UInt16 = 0b1000_0000_0000_0000
        for i in 0..<vals.count {
            var v = CFSwapInt16LittleToHost(vals[i])
            let negative : Bool = 0 != (v & signBit)
            if negative {
                v = ~v
                ++v
            }
            ret[i] = Int16( v ) * (negative ? -1 : 1)
        }

        return ret
    }

    /// slice fourBytes to three 10-bit signed numbers
    func decodeAccelWord(fourBytes: [UInt8]) -> Acceleration
    {
        let xWord : UInt16 = (UInt16(fourBytes[0]) << 2) | UInt16(fourBytes[1] >> 6)
        let yWord : UInt16 = (UInt16(fourBytes[1] & 0b0011_1111) << 4) | UInt16(fourBytes[2] >> 4)
        let zWord : UInt16 = (UInt16(fourBytes[2] & 0b0000_1111) << 6) | UInt16(fourBytes[3] >> 2)

        return (fixSignBit10(xWord), fixSignBit10(yWord), fixSignBit10(zWord))
    }

    /// convert a 10-bit signed integer to 16-bit signed integer
    func fixSignBit10(n : UInt16) -> Int16
    {
        var ret = Int16(n)
        let signBit = UInt16(1) << 9
        if (0 != signBit & n) {
            ret |= Int16(-1) << 9
        }
        return ret
    }

}