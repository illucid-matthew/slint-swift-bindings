# Slint bindings for Swift

Attempt at creating bindings for Slint in Swift, re-using the private FFI interface meant for the C++ bindings.

__Status__: 🚧 _Under construction_.

I'm able to build and link an application, and can call the private API from Swift.

Next up I guess is to implement the tests from the C++ bindings, and make them function.

## How It's Made

- The C++ library is built following the example Slint C++ template.
- A Swift library is built, pulling in Slint.
- A module map and bridging header are overlaid where Slint is built.
- The bridging header `FFI.h` makes the `extern "C"` declarations visible, among other things.
- The modulemap tells `clang` what's there, so it can be accessed in Swift.

Note that Swift won't import functions or types that are marked `extern "C"` when in C++ interop mode, so they must be bridged to C++ in a header before they are accessible.

### Resources

- [Swift: Mixing Swift and C++](https://www.swift.org/documentation/cxx-interop/)
- [Swift: Mixing Swift and C++ Using Other Build Systems](https://www.swift.org/documentation/cxx-interop/project-build-setup/#mixing-swift-and-c-using-other-build-systems)
- [Swift: Wrapping C/C++ Library in Swift](https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html)
- [GitHub: apple/swift-cmake-examples](https://github.com/apple/swift-cmake-examples/tree/main/3_bidirectional_cxx_interop)
- [Github: slint-ui/slint-cpp-template](https://github.com/slint-ui/slint-cpp-template/blob/main/CMakeLists.txt)
