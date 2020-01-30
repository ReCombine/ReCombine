import XCTest

import ReCombineTests
import ReCombineTestTests

var tests = [XCTestCaseEntry]()
tests += ReCombineTests.allTests()
tests += ReCombineTestTests.allTests()
XCTMain(tests)
