# Slint bindings for Swift

Attempt at creating bindings for Slint in Swift, re-using the private FFI interface meant for the C++ bindings.

See also: [WIP Python bindings](https://github.com/slint-ui/slint/pull/4155)

__Status__: 🚧 _Under construction_.

Currently implemented:

- [x] Prerequisites
    - [x] Include Slint as CMake dependency
    - [x] Create module map for Slint FFI headers[^1]
    - [x] Configure build to enable Swift-C++ interop
    - [x] Call Slint FFI from Swift
    - [ ] Testing
- [ ] Core Library
    - [x] Starting and stopping the event loop
    - [x] Running callbacks from the event loop
    - [ ] Timers
    - [ ] Core type conversions
        - [ ] Callback
        - [ ] Shared string
        - [ ] Shared vector
        - [ ] Property
        - [ ] Property tracker
        - [ ] Path
        - [ ] Image
        - [ ] Color
        - [ ] Brush
- [ ] Interpreter
    - [ ] Value
    - [ ] Struct
    - [ ] Model
    - [ ] Component compiler
    - [ ] Component definition (created by component compiler)
    - [ ] Component (created from component definition)

> Note: List is weakly orderd.

[^1]: The foreign-function interface (FFI) uses C calling convention, but the generated headers are C++. Swift will not import any `extern "C"` symbols when C++ interop is enabled, so a bridging header is used to make them accessible.

## Building/Running

To build the example, run:

    $ mkdir build
    $ cmake -B build -GNinja
    $ cmake --build build
    $ ./build/Example/Example

~~You should then see:~~
_Note: This is out of date._

    Hello from the Swift application 🏗️!
    Hello from the Swift library! 🔨
    Setting up timer ⏰ (random value: 28)
    Starting event loop 🔁

And then it will hang for 5 seconds. Then, you'll see:

    Called from event loop 👍 (random value: 28)
    Done! 🤓

## How It Works

### Swift Interop

- The C++ library is built by CMake, following the example Slint C++ template.
- A module map and bridging header are overlaid where Slint was built.
- The modulemap allows Swift to import Slint's FFI as `SlintFFI`.
- A Swift library CMake target is created, linking to Slint.
- Applications can link to that library.

Swift won't import functions or types that are marked `extern "C"` when in C++ interop mode.
They must be bridged to C++ in a header before they are accessible.

This is why there is a bridging header.
Additionaly, the bridging header allows for types to be accessed from the global namespace, instead of `slint::cbindgen_private::…`.

### Event Loop and Actor Isolation

Generally, Slint APIs can only be used from the main thread.
This is meant to prevent data races when the framework and application are concurrently accessing the UI state.

Swift's concurrency model generalizes this into _actors_.
An actor can only do one thing at a time.

There are actually two types of actors:
- Instance actors
- Global actors
 
Instance actors are special classes that ensure their mutable state can only be accessed from one place at a time.

Global actors ensure only one piece of code can be running at a time.
Code run by a global actor is said to be _isolated_ to that actor, or running it the actor's _isolation context_.

Since Slint APIs can only be used from the main thread, we could say that they're isolated to the _main actor_.
But that runs into a problem at runtime.

To start Slint's event loop, the library calls a function named `slint_run_event_loop()` on the main thread.
This function _blocks_, meaning no other code can run on the main thread until it returns.

So, how do you access Slint's APIs?
They must be called from the main thread, but the event loop blocks the main thread!

Slint does have a solution: `slint_post_event()`, which can run from _any_ thread.
This function allows us to run code from the Slint event loop, and thus, the main thread.
Finally, we can use those APIs!

But manually using `slint_post_event()` _every time_ we want to interact with Slint would be tedious and error-prone.
Thankfully, Swift allows us to define our own global actor for this very use!

Enter `SlintActor`.
Take the `Timer` class for example.
```swift
@SlintActor
class Timer {
    var id
    func start()
    func stop()
    func restart()
}
```

The `@SlintActor` attribute tells Swift that any code that accesses `Timer` must be executed by `SlintActor`.
Because actors can only do one thing at a time, only one piece of code can be accessing `Timer` at any point in time.
This attribute can be applied to any type, including functions.

Any code run by `SlintActor` can immediately access a `Timer`, because it's already isolated to `SlintActor`.
Code running outside of `SlintActor` can access it, but must wait.

```swift
func someTask() {
    // Because this code is running from a different
    // context, it must wait to get access to the timer.
    await someTimer.restart()
}

@SlintActor
func runningFromEventLoop() {
    // Because this code is running from the same isolation
    // context, it can access the timer without waiting.
    someTimer.start()
}
```

In Swift, it's common to pass around closures, providing code to run in a different location.
This is used in place of callbacks and function pointers, and provide a richer set of features.

```swift
struct WorkItem {
    var whatToDo: () -> Void
}

let someWork = WorkItem(whatToDo: {
    print("Hello there!")
})

// Later…
someWork.whatToDo()
```

When defining a closure's type, we can apply attributes, same as functions.
This allows us to provide Swift with more information about how the closure will be used.

This is used all over the place in the Swift bindings.
To return to `Timer`:
```swift
class Timer {
    …
    func start(after: Int, do: @SlintActor @escaping () -> Void) { … }
}
```

By using the `@SlintActor` attribute in the closure's type signature, we tell Swift that the closure will be ran in the isolation context of `SlintActor`.
This means the closure can access isolated types like `Timer` _without_ waiting, or explicitly requesting isolation!

```swift
// Outside of `SlintActor` isolation, this code must wait to call `start()`
await anotherTimer.start(after: 10) {

    // But this code will always be isolated, so it doesn't have to wait!
    anotherTimer.restart()
}
```

So, to ensure safety, all types that directly call Slint's API are marked `@SlintActor`. This guarentees they will never attempt to call the Slint API from outside the main thread.

This is directly integrated into the Swift concurrency model, so you can use asynchronous code in your application without worry.

___That said___, any Swift code that attempts to run isolated to `@MainActor` will still have to wait until the event loop stops.
If it becomes an issue, it may be possible to use `MainActor.assumeIsolated()` and `isSameExclusiveExecutionContext()` to 'prove' that `SlintActor` is basically equivalent to `MainActor`.
Or maybe [this will save us](https://github.com/apple/swift-evolution/blob/main/proposals/0392-custom-actor-executors.md#overriding-the-mainactor-executor).

## Addendums

### The FFI

The FFI interface is generated by the `cbindgen`, which analyzes the Slint crates to find things to bridge.

From the C++ binding's CMake file to the FFI:
1. The CMake lists pulls in `corrosion`, which gives CMake access to Rust crates.
2. `corrosion` pulls in the `slint-cpp` crate.
3. The `slint-cpp` crate pulls in the core Slint crates and `cbindgen`.
4. The `slint-cpp` build script `build.rs` creates directories for generated headers, and calls `cbindgen::gen_all()`.
5. `gen_all()` is defined in `cbindgen.rs`. It generates the headers for an FFI interface.

The items that are generated by `gen_all()` are, in order:
1. Enumerations

    There doesn't appear to be any issues with these.

2. Built-in Structs

    Some of these reference `SharedString`, and it is forward declared in `slint_string_internal.h`.
    This type is defined in Rust, but is excluded from being exported by `cbindgen`.
    The C++ bindings provide an implemenatation.

3. Core Library

    The set of types needed for the Slint runtime are explicitly listed here.
    Another list of types to exclude are here, including `SharedString` and `SharedVector`.

    The files generated are, in order:

    1. `slint_string_internal.h`
    2. `slint_sharedvector_internal.h`
    3. `slint_properties_internal.h`
    4. `slint_timer_internal.h`
    5. Using many of the graphics Rust files, but a different config to pull in specific things:
        1. `slint_image_internal.h`
        2. `slint_color_internal.h`
        3. `slint_pathdata_internal.h`
        4. `slint_brush_internal.h`
    6. `slint_generated_public.h`
    7. `slint_internal.h`

4. Qt Backend

    Has a list of items to export, and automatically pulls in anything else required.

5. Platform

    This one is interesting.
    Instead of working from within Slint's crates, it instead generates a header for `platform.rs` in the `api/cpp` directory.
    The very same one that `cbindgen.rs` is located in.

6. _If enabled,_ Interpreter

    Excludes some common types and specific items, and then picks up everything in the `internal/interpreter` crate.

## Resources

- [Swift: Mixing Swift and C++](https://www.swift.org/documentation/cxx-interop/)
- [Swift: Mixing Swift and C++ Using Other Build Systems](https://www.swift.org/documentation/cxx-interop/project-build-setup/#mixing-swift-and-c-using-other-build-systems)
- [Swift: Wrapping C/C++ Library in Swift](https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html)
- [GitHub: apple/swift-cmake-examples](https://github.com/apple/swift-cmake-examples/tree/main/3_bidirectional_cxx_interop)
- [Github: slint-ui/slint-cpp-template](https://github.com/slint-ui/slint-cpp-template/blob/main/CMakeLists.txt)

## Acknowledgements

 - `AsyncChannel`, from [Building a Channel with Swift Concurrency Continuations by Alejandro Martinez](https://alejandromp.com/blog/building-a-channel-with-swift-concurrency-continuations/)
