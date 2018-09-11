import XCTest

import TemporaryFileTests

var tests = [XCTestCaseEntry]()
tests += TemporaryFileTests.allTests()
XCTMain(tests)