//
//  PostureDecoderTests.swift
//  PostureDecoderTests
//
//  Created by Yonat Sharon on 3/9/14.
//  Copyright (c) 2014 Yonat Sharon. All rights reserved.
//

import UIKit
import XCTest

class PostureDecoderTests: XCTestCase {

    var coder = PostureSenseDecoder()

    override func setUp() {
        super.setUp()
        coder.accelerometerOffsets = [0, 0, 0, 0, 0, 0]
        coder.sensorOffsets = [0, 0, 0, 0, 0, 0]
        coder.sensorCoefficients = [1, 1, 1, 1, 1, 1]
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testZeroCalibreation() {
        var binary = [UInt16](count: 6, repeatedValue: 0)
        let data = NSData(bytes: &binary, length: 12)
        coder.setSensorOffsets(data)
        XCTAssertEqual(coder.sensorOffsets.count, 6, "6 offsets")
        for offset in coder.sensorOffsets {
            XCTAssertEqual(offset, 0, "offset is 0")
        }
    }

    func test17Calibration() {
        var binary : [UInt8] = [17, 0, 17, 0, 17, 0, 17, 0, 17, 0, 17, 0]
        let data = NSData(bytes: &binary, length: 12)
        coder.setSensorCoefficients(data)
        XCTAssertEqual(coder.sensorCoefficients.count, 6, "6 coefficients")
        for coefficient in coder.sensorCoefficients {
            XCTAssertEqual(coefficient, 17, "coefficient is 17")
        }
    }

    func testMinus17Calibration() {
        var minusSeventeen = UInt16.max - 16 // two's complement
        minusSeventeen = CFSwapInt16HostToLittle(minusSeventeen)
        var binary : [UInt16] = [minusSeventeen, minusSeventeen, minusSeventeen, minusSeventeen, minusSeventeen, minusSeventeen]
        let data = NSData(bytes: &binary, length: 12)
        coder.setSensorCoefficients(data)
        XCTAssertEqual(coder.sensorCoefficients.count, 6, "6 coefficients")
        for coefficient in coder.sensorCoefficients {
            XCTAssertEqual(coefficient, -17, "coefficient is -17")
        }
    }

    func testShortCalibrationDataLength() {
        var binary : [UInt8] = [17, 0, 17, 0, 17, 0, 17, 0, 17, 0]
        let data = NSData(bytes: &binary, length: 10)
        coder.setSensorOffsets(data)
        XCTAssertEqual(coder.sensorOffsets.count, 6, "6 offsets")
        for i in 0...4 {
            XCTAssertEqual(coder.sensorOffsets[i], 17, "calibreated offset is 17")
        }
        XCTAssertEqual(coder.sensorOffsets[5], 0, "last offset is 0")
    }

    func testLongCalibrationDataLength() {
        var binary : [UInt8] = [17, 0, 17, 0, 17, 0, 17, 0, 17, 0, 17, 0, 17, 0]
        let data = NSData(bytes: &binary, length: 14)
        coder.setSensorCoefficients(data)
        XCTAssertEqual(coder.sensorOffsets.count, 6, "6 coefficients")
        for coefficient in coder.sensorCoefficients {
            XCTAssertEqual(coefficient, 17, "coefficient is 17")
        }
    }

    func testZeroRealtimeData() {
        var binary = [UInt16](count: 10, repeatedValue: 0)
        let data = NSData(bytes: &binary, length: 20)
        let p = coder.decodeRealTimeData(data)
        XCTAssertEqual(p.angles.count, 6, "6 angles")
        XCTAssertEqual(p.attitudes.count, 2, "2 attitudes")
        for angle in p.angles {
            XCTAssertEqual(angle, 0, "angle is 0")
        }
        for attitude in p.attitudes {
            XCTAssertEqual(attitude.x, 0, "attitude.x is 0")
            XCTAssertEqual(attitude.y, 0, "attitude.y is 0")
            XCTAssertEqual(attitude.z, 0, "attitude.z is 0")
        }
    }

    func test42RealtimeData() {

        // sensor values
        var sensorVals = [UInt16](count: 6, repeatedValue: 42)
        var data = NSMutableData(bytes: &sensorVals, length: 12)

        // compressed accelerometer values
        var accelVals : [UInt8] = [0b0000_1010, 0b10_0000_10, 0b1010_0000, 0b101010_00]
        accelVals += accelVals
        data.appendBytes(&accelVals, length: 8)

        let p = coder.decodeRealTimeData(data)
        XCTAssertEqual(p.angles.count, 6, "6 angles")
        XCTAssertEqual(p.attitudes.count, 2, "2 attitudes")
        for angle in p.angles {
            XCTAssertEqual(angle, 42, "angle is 42")
        }
        for attitude in p.attitudes {
            XCTAssertEqual(attitude.x, 42, "attitude.x is 42")
            XCTAssertEqual(attitude.y, 42, "attitude.y is 42")
            XCTAssertEqual(attitude.z, 42, "attitude.z is 42")
        }
    }

    func testMinus42RealtimeData() {

        // sensor values
        var sensorVals = [Int16](count: 6, repeatedValue: -42)
        var data = NSMutableData(bytes: &sensorVals, length: 12)

        // compressed accelerometer values
        var accelVals : [UInt8] = [0b1111_0101, 0b10_1111_01, 0b0110_1111, 0b010110_00]
        accelVals += accelVals
        data.appendBytes(&accelVals, length: 8)

        let p = coder.decodeRealTimeData(data)
        XCTAssertEqual(p.angles.count, 6, "6 angles")
        XCTAssertEqual(p.attitudes.count, 2, "2 attitudes")
        for angle in p.angles {
            XCTAssertEqual(angle, -42, "angle is -42")
        }
        for attitude in p.attitudes {
            XCTAssertEqual(attitude.x, -42, "attitude.x is -42")
            XCTAssertEqual(attitude.y, -42, "attitude.y is -42")
            XCTAssertEqual(attitude.z, -42, "attitude.z is -42")
        }
    }

    func testBadRealtimeDataLength() {
        // sensor values
        var sensorVals = [UInt16](count: 6, repeatedValue: 42)
        var data = NSMutableData(bytes: &sensorVals, length: 12)

        // compressed accelerometer values
        var accelVals : [UInt8] = [0b0000_1010, 0b10_0000_10, 0b1010_0000, 0b101010_00]
        data.appendBytes(&accelVals, length: 4)

        let p = coder.decodeRealTimeData(data)
        XCTAssertEqual(p.angles.count, 6, "6 angles")
        XCTAssertEqual(p.attitudes.count, 2, "2 attitudes")
        for angle in p.angles {
            XCTAssertEqual(angle, 42, "angle is 42")
        }

        // first legitemate attitude
        XCTAssertEqual(p.attitudes[0].x, 42, "attitude.x is 42")
        XCTAssertEqual(p.attitudes[0].y, 42, "attitude.y is 42")
        XCTAssertEqual(p.attitudes[0].z, 42, "attitude.z is 42")

        // second empty attitude
        XCTAssertEqual(p.attitudes[1].x, 0, "attitude.x is 0")
        XCTAssertEqual(p.attitudes[1].y, 0, "attitude.y is 0")
        XCTAssertEqual(p.attitudes[1].z, 0, "attitude.z is 0")
    }

}
