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
        public nonisolated var unownedExecutor: UnownedSerialExecutor { SlintEventLoopExecutor.shared.asUnownedSerialExecutor() }
    }

    public static let shared = SlintEventLoop()
}

/*

NOTE: DO NOT USE

/// Convience function. Runs a closure in the Slint event loop, capturing the value.
/// - Parameter closure: The closure to run. Throwing an error counts as `nil`.
/// - Returns: The closure return value, or `nil`.
/// 
/// Example:
/// ```swift
/// let running = await SlintTask {
///     return slint_timer_running(id)
/// }
/// ```
@discardableResult
public func SlintTask<Ret>(_ closure: @escaping @Sendable () throws -> Ret) async -> Ret? {
    /// Task to run in the Slint event loop.
    let task = Task { @SlintActor in
        return try? closure()
    }
    
    /// Return the value, or `nil` if it failed for any reason.
    return await task.value
}

/// Convience function. Runs a closure in the Slint event loop, from a synchronous context.
/// - Parameter closure: The closure to run.
/// 
/// Note: you cannot wait for a returned value. You must use the asynchronous version,
/// `SlintTask(_:)`, and await the result.
/// 
/// The reason is that to wait for the return value from a synchronous context would require
/// blocking the thread that the synchronous function was running on. This contradicts the Swift
/// asynchronous model.
/// 
/// Imagine if we tried to block to wait for the result; if this was called from the
/// Slint event loop, we would be waiting forever! The Slint event that would run the
/// closure would be permanently stuck in the blocking caller.
/// 
/// So this is only suitable for 'fire and forget' calls (or near enough).
/// 
/// See more: https://stackoverflow.com/a/71971635
public func SlintDetached(_ closure: @escaping @Sendable () -> Void) {
    Task { @SlintActor in closure() }
}
*/