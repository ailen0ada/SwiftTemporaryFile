import XCTest

import TemporaryFileTests

var tests = [XCTestCaseEntry]()
tests += TemporaryFileTests.__allTests()

XCTMain(tests)
