// Based on: https://github.com/apple/swift-atomics/blob/main/Tests/AtomicsTests/main.swift
#if MANUAL_TEST_DISCOVERY
import XCTest

var testCases = [
    testCase(ExampleTests.allTests),
]

XCTMain(testCases)
#endif