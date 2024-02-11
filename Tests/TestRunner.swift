// Based on: https://github.com/google/swift-benchmark/blob/main/Tests/LinuxMain.swift
import SlintTests
import XCTest

var tests = [XCTestCaseEntry]()
tests += BenchmarkTests.allTests()
XCTMain(tests)