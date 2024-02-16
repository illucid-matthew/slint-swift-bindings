# Based on: https://github.com/google/swift-benchmark/blob/main/Tests/CMakeLists.txt
include(CTest)

# Testing wasn't working due to wonky path stuff: https://stackoverflow.com/a/61725799
# xcrun --find xctest

# Still an issue: https://github.com/leetal/ios-cmake/issues/37
find_package(XCTest CONFIG QUIET)

if(NOT XCTest_FOUND)
    message(STATUS "XCTest could not be found, attempting workaround…")
    set(CMAKE_SYSTEM_NAME Darwin FORCE)
    find_package(XCTest REQUIRED)
    find_package(XCTest CONFIG)
endif()

if(NOT XCTest_FOUND)
    message(WARNING "XCTest could not be found, skipping tests!")
else()    

    add_executable(SlintTestBundle
        Slint/main.swift
        Slint/ExampleTests.swift
    )

    target_compile_options(SlintTestBundle PRIVATE "-DMANUAL_TEST_DISCOVERY")

    target_link_libraries(SlintTestBundle PRIVATE
        SlintUI
        XCTest
    )

    add_test(NAME Slint COMMAND SlintTestBundle)

endif()

