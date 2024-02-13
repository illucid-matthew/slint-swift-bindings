//
// SlintActor.swift
// slint
//
// Created by Matthew Taylor on 2/12/24.
//

/// This was more difficult that it should have been.
/// Even now, I don't know what specifically was causing the crashes, or what fixed them.
///
/// See: [Global Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0316-global-actors.md)
/// See: [`borrowing` and `consuming` Parameter Ownership Modifiers](https://github.com/apple/swift-evolution/blob/main/proposals/0377-parameter-ownership-modifiers.md)
/// See: [Custom Actor Executors](https://github.com/apple/swift-evolution/blob/main/proposals/0392-custom-actor-executors.md)
/// See: [How async/await works internally in Swift](https://swiftrocks.com/how-async-await-works-internally-in-swift)
/// See: [How `@MainActor` works](https://oleb.net/2022/how-mainactor-works/)
/// See: [swiftwasm/JavaScriptKit: `JavaScriptEventLoop.swift`](https://github.com/swiftwasm/JavaScriptKit/blob/main/Sources/JavaScriptEventLoop/JavaScriptEventLoop.swift)

import SlintFFI

/// Wrapper for an event. This is necessary because the closure that runs the job needs to capture a reference to the event loop.
private class SlintEventLoopEventWrapper {
    private let _invoke: () -> Void
    init(_ event: @escaping @Sendable () -> Void) {
        _invoke = event
    }
    func invoke() { _invoke() }
}

/// Executor that takes queued jobs and posts them to Slint's event loop.
final class SlintEventLoopExecutor: SerialExecutor {
    /// Private initializer.
    private init() { }

    /// A singleton instance of this Executor.
    public static let shared = SlintEventLoopExecutor()

    /// Required by `SerialExecutor`.
    public func enqueue(_ job: consuming ExecutorJob) {
        postJobEvent(UnownedJob(job))
    }

    /// Get an unowned reference to the shared instance.
    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        return UnownedSerialExecutor(ordinary: self)
    }

    private typealias SlintEventCallback = (@convention(c) (UnsafeMutableRawPointer?) -> Void)?
    private typealias SlintDropUserDataCallback = (@convention(c) (UnsafeMutableRawPointer?) -> Void)?

    private let slintEventCallback: SlintEventCallback =
    { userDataPtr in
        // Convert to instance reference
        let wrapper = Unmanaged<SlintEventLoopEventWrapper>.fromOpaque(userDataPtr!).takeUnretainedValue()
        
        // Invoke
        wrapper.invoke()
    }

    private let slintDropUserDataCallback: SlintDropUserDataCallback =
    { userDataPtr in
        // Convert the raw pointer to an unmanaged reference and release
        _ = Unmanaged<SlintEventLoopEventWrapper>.fromOpaque(userDataPtr!).takeRetainedValue()
    }

    /// Take the unowned job, and post it as an event for Slint.
    private func postJobEvent(_ job: UnownedJob) {
        // Create a wrapper that runs the job.
        let wrapper = SlintEventLoopEventWrapper {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }

        // Get an unmanaged reference to it.
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

        // Post the event
        slint_post_event(
            slintEventCallback,
            wrapperPtr,
            slintDropUserDataCallback
        )
    }
}

/// A singleton actor that runs jobs in the Slint event loop.
/// 
/// Slint requires that its functions be called from the same thread as the event loop.
/// Running the event loop blocks, so Swift can't run tasks on the same thread.
/// 
/// This actor instead uses `SlintEventLoopExecutor`, which runs jobs in the Slint event loop.
/// 
/// Any code that calls Slint FFI directly should be annotated `@SlintActor`, to ensure it's ran in the event loop.
/// 
/// Note: If the event loop has not started, jobs will be queued, but not run.
///
@globalActor
public struct SlintActor {
    /// Actor that uses the `SlintEventLoopExecutor` singleton to serialize access.
    public actor SlintEventLoop {
        public nonisolated var unownedExecutor: UnownedSerialExecutor { SlintEventLoopExecutor.shared.asUnownedSerialExecutor() }
    }

    public static let shared = SlintEventLoop()
}