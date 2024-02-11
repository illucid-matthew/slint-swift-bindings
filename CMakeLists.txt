cmake_minimum_required(VERSION 3.26)
project(SlintSwift LANGUAGES Swift CXX)

# Testing stuff: https://cliutils.gitlab.io/modern-cmake/chapters/testing.html
# Currently NOT ENABLED, because I'm having strange issues with locating XCTest.
# I'll figure it out later. 
#
# if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
#   include(CTest)
# endif()
#
# if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME AND BUILD_TESTING)
#     add_subdirectory(Tests)
# endif()

# Do the Swift setup stuff.
# Not strictly required, but helpful.

# Verify that we have a new enough compiler
if("${CMAKE_Swift_COMPILER_VERSION}" VERSION_LESS 5.9)
  message(FATAL_ERROR "Bidirectional C++ Interop requires Swift 5.9 or greater. Have ${CMAKE_Swift_COMPILER_VERSION}")
endif()

if(NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND
   NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
  message(FATAL_ERROR "Project requires building with Clang.
  Have ${CMAKE_CXX_COMPILER_ID}")
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

# Set up swiftrt.o and runtime library search paths
include(InitializeSwift)
# cmake/modules/AddSwift.cmake provides the function for creating the Swift to C++ bridging header
include(AddSwift)

# Bring in Slint's C++ bindings.
# We're not really interested in the C++ bindings themselves, but the private headers and symbols.
include(FetchContent)

message("Fetching Slint…")
FetchContent_Declare(
  Slint_CPP
  GIT_REPOSITORY https://github.com/slint-ui/slint.git
  GIT_TAG release/1
  GIT_SHALLOW TRUE

  SOURCE_SUBDIR api/cpp

  UPDATE_COMMAND ""
  CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
)
FetchContent_MakeAvailable(Slint_CPP)
set(Slint_FFI_INCLUDE_DIR "${Slint_BINARY_DIR}/generated_include")

#
# Module map
#
set(Slint_MODULEMAP_FILE "${CMAKE_SOURCE_DIR}/Bridging/Slint.modulemap")
set(Slint_FFI_HEADER "${CMAKE_SOURCE_DIR}/Bridging/FFI.h")

configure_file(Bridging/Slint-overlay.yaml "${CMAKE_CURRENT_BINARY_DIR}/Slint-overlay.yaml")

# This does the following:
# 1. Enables the overlay, placing `Slint.modulemap` and `FFI.h` in `generated_header/`.
# 2. Enables C++ interop for Swift
# 3. Pass required C++ version to the Clang compiler
target_compile_options(Slint INTERFACE
  "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-vfsoverlay ${CMAKE_CURRENT_BINARY_DIR}/Slint-overlay.yaml -cxx-interoperability-mode=default -Xcc -std=c++20>")


add_subdirectory("Sources/")
add_subdirectory("Example/")
