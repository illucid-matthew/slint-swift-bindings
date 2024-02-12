add_library(SlintTests
    # Add test files here:
    ExampleTests.swift
    
    # Finally, the manifest
    XCTTestManifests.swift
)

# Create a library with tests
target_link_libraries(SlintTests PRIVATE
    SlintUI
    XCTest
)