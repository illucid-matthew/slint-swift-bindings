# Based on: https://github.com/google/swift-benchmark/blob/main/Tests/CMakeLists.txt
include(CTest)

find_package(XCTest CONFIG QUIET)

add_subdirectory(SlintTests)

# Build a test runner, link to the tests library
add_executable(SlintTestRunner TestRunner.swift)
target_link_libraries(SlintTestRunner PRIVATE
    SlintTests
    XCTest
)

# Add it as a test
add_test(NAME Slint COMMAND SlintTestRunner)