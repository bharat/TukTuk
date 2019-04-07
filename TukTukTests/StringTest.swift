//
//  StringTest.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 2/14/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import XCTest

class StringTest: XCTestCase {
    func testCamelCaseToWords_BaseCase() {
        XCTAssertEqual("Affen", "Affen".camelCaseToWords())
        XCTAssertEqual("Two Words", "TwoWords".camelCaseToWords())
    }

    func testCamelCaseToWords_EdgeCases() {
        XCTAssertEqual("99 Balloons", "99Balloons".camelCaseToWords())
        XCTAssertEqual("", "".camelCaseToWords())
    }
}
