//
//  SlintActor.swift
//  slint
//
//  Created by Matthew Taylor on 2/12/24.
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

/// Executor that takes queued jobs and posts them to Slint's event loop.
final class SlintEventLoopExecutor: SerialExecutor {
    /// Private initializer.
    private init() { }

    /// A singleton instance of this Executor.
    public static let shared = SlintEventLoopExecutor()

    /// Execute the job in the Slint event loop. Required by `SerialExecutor`.
    @inlinable
    public func enqueue(_ job: consuming ExecutorJob) {

        let unownedJob = UnownedJob(job)

        let wrapper = WrappedClosure {
            unownedJob.runSynchronously(on: self.asUnownedSerialExecutor())
        }

        // Post as an event
        slint_post_event(
            WrappedClosure.invokeCallback,
            wrapper.getRetainedPointer(),
            WrappedClosure.dropCallback
        )
    }

    /// Get an unowned reference to the shared instance.
    @inlinable
    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        return UnownedSerialExecutor(ordinary: self)
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
        public nonisolated var unownedExecutor: UnownedSerialExecutor { _executor }
    }

    public static var shared = SlintEventLoop()
}

// Global variables? Really?
fileprivate var _executor = SlintEventLoopExecutor.shared.asUnownedSerialExecutor()
// UNSAFE UNSAFE UNSAFE AND STUPID AND DUMB
// Swapping executor mid-execution may have huge reprucutions that I can't even fathom.
@MainActor
func SwitchToMainActorExecutor() {
    _executor = MainActor.sharedUnownedExecutor
}

@MainActor
func SwitchToEventLoopExecutor() {
    _executor = SlintEventLoopExecutor.shared.asUnownedSerialExecutor()
}