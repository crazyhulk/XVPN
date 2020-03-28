//
//  XVPNTests.swift
//  XVPNTests
//
//  Created by 哔哩哔哩 on 2019/6/19.
//  Copyright © 2019 xizi. All rights reserved.
//

import XCTest
@testable import XVPN

class XVPNTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let protocols:[NSNumber] = [NSNumber].init(repeating: NSNumber.init(value: AF_INET), count: 3)
        assert(protocols.count == 3)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testSomething() {
        let protocols:[NSNumber] = [NSNumber].init(repeating: NSNumber.init(value: AF_INET), count: 3)
        assert(protocols.count == 3)
        assert(protocols[2].int32Value == AF_INET)
        assert(protocols.count == 3)
        
    }
}
