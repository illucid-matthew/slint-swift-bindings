// Based on: https://github.com/google/swift-benchmark/blob/main/Tests/BenchmarkTests/XCTTestManifests.swift
import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(BenchmarkColumnTests.allTests),
            testCase(BenchmarkCommandTests.allTests),
            testCase(BenchmarkReporterTests.allTests),
            testCase(BenchmarkRunnerTests.allTests),
            testCase(BenchmarkSettingTests.allTests),
            testCase(BenchmarkSuiteTests.allTests),
            testCase(CustomBenchmarkTests.allTests),
            testCase(StatsTests.allTests),
        ]
    }
#endif