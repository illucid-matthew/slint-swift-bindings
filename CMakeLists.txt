cmake_minimum_required(VERSION 3.26)

project(SlintSwift LANGUAGES Swift CXX)

# Bring in Slint's C++ bindings.
# We're not really interested in the C++ bindings themselves, but the private headers and symbols.

# https://github.com/slint-ui/slint-cpp-template/blob/main/CMakeLists.txt
# https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html
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

message("Slint binary dir: ${Slint_BINARY_DIR}")
set(Slint_FFI_INCLUDE_DIR "${Slint_BINARY_DIR}/generated_include")

#
# Module map
#
set(Slint_MODULEMAP_FILE "${CMAKE_SOURCE_DIR}/Interop/Slint.modulemap")
set(Slint_FFI_HEADER "${CMAKE_SOURCE_DIR}/Interop/FFI.h")

configure_file(Interop/Slint-overlay.yaml "${CMAKE_CURRENT_BINARY_DIR}/Slint-overlay.yaml")

# This does the following:
# 1. Enables the overlay, placing `Slint.modulemap` and `FFI.h` in `generated_header/`.
# 2. Enables C++ interop for Swift
# 3. Pass required C++ version to the Clang compiler
target_compile_options(Slint INTERFACE
  "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-vfsoverlay ${CMAKE_CURRENT_BINARY_DIR}/Slint-overlay.yaml -cxx-interoperability-mode=default -Xcc -std=c++20>")

list(APPEND SlintSwift_LIB_SOURCE_FILES
  Sources/Timer.swift
)

add_library(SlintSwift ${SlintSwift_LIB_SOURCE_FILES})
target_link_libraries(SlintSwift PUBLIC Slint)

add_executable(ExampleApp Sources/Example.swift Sources/Timer.swift)
target_link_libraries(ExampleApp PUBLIC SlintSwift)