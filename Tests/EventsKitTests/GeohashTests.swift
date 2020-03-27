// The MIT License (MIT)
//
// Copyright (c) 2016 Naoki Hiroshima
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// https://github.com/nh7a/Geohash

import XCTest
@testable import TjekSDK

class GeohashTests: XCTestCase {
    func testDecode() {
        XCTAssertNil(Geohash.decode(hash: "garbage"))
        
        let (lat, lon) = Geohash.decode(hash: "u4pruydqqvj")!
        XCTAssertTrue(lat.min == 57.649109959602356)
        XCTAssertTrue(lat.max == 57.649111300706863)
        XCTAssertTrue(lon.min == 10.407439023256302)
        XCTAssertTrue(lon.max == 10.407440364360809)
    }
    
    func testEncode() {
        let (lat, lon) = (57.64911063015461, 10.40743969380855)
        let chars = "u4pruydqqvj"
        for i in 1...chars.count {
            XCTAssertTrue(Geohash.encode(latitude: lat, longitude: lon, length: i) == String(chars.prefix(i)))
        }
        XCTAssertTrue(Geohash.encode(latitude: lat, longitude: lon, precision: .twentyFiveHundredKilometers) == String(chars.prefix(1)))
        XCTAssertTrue(Geohash.encode(latitude: lat, longitude: lon, precision: .twentyFourHundredMeters) == String(chars.prefix(5)))
        XCTAssertTrue(Geohash.encode(latitude: lat, longitude: lon, precision: .seventyFourMillimeters) == String(chars.prefix(11)))
    }
}

#if canImport(CoreLocation)

import CoreLocation

class GeohashLocationTests: XCTestCase {
    func testCoreLocation() {
        XCTAssertFalse(CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(geohash: "garbage")))
        
        let hash = "u4pruydqqvj"
        
        let c = CLLocationCoordinate2D(geohash: hash)
        XCTAssertTrue(CLLocationCoordinate2DIsValid(c))
        XCTAssertTrue(c.geohash(length: 11) == hash)
        XCTAssertTrue(c.geohash(precision: .twentyFiveHundredKilometers) == String(hash.prefix(1)))
        XCTAssertTrue(c.geohash(precision: .twentyFourHundredMeters) == String(hash.prefix(5)))
        XCTAssertTrue(c.geohash(precision: .seventyFourMillimeters) == hash)
    }
}

#endif
