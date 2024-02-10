# Slint bindings for Swift

Note that Swift won't import functions or types that are marked `extern "C"` when in C++ interop mode, so they must be bridged to C++ in a header before they are accessible.

#### Resources

- [Swift: Mixing Swift and C++](https://www.swift.org/documentation/cxx-interop/)
- [Swift: Mixing Swift and C++ Using Other Build Systems](https://www.swift.org/documentation/cxx-interop/project-build-setup/#mixing-swift-and-c-using-other-build-systems)
- [Swift: Wrapping C/C++ Library in Swift](https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html)
- [GitHub: apple/swift-cmake-examples](https://github.com/apple/swift-cmake-examples/tree/main/3_bidirectional_cxx_interop)
- [Github: slint-ui/slint-cpp-template](https://github.com/slint-ui/slint-cpp-template/blob/main/CMakeLists.txt)
