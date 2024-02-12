# Based on: https://github.com/google/swift-benchmark/blob/main/Tests/CMakeLists.txt
# include(CTest)

# Testing wasn't working due to wonky path stuff: https://stackoverflow.com/a/61725799
# xcrun --find xctest
find_package(XCTest CONFIG)

if(NOT XCTest_FOUND)
    message(WARNING "XCTest could not be found, skipping tests!")
else()
    add_subdirectory(Slint)

    # Build a test runner, link to the tests library
    add_executable(SlintTestRunner TestRunner.swift)
    target_link_libraries(SlintTestRunner PRIVATE
        SlintTests
        XCTest
    )

    # Add it as a test
    add_test(NAME Slint COMMAND SlintTestRunner)
endif()
