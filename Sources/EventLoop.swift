//
//  EventLoop.swift
//  slint
//
//  Created by Matthew Taylor on 2/10/24.
//

import SlintFFI

// Deadlock hell.
// It was deadlocking while waiting for `ready`, until I moved the `startBeforeLoopRunning` call from `init` into `start`.
// I can't quite put my finger on why. Diagnostic messages showed the timer was setup before the event loop started.
//
// Maybe it's because the closure captures `self`, and something about doing that in the initializer trips it up.
// Testing reveals that's not the case. Putting it in a seperate `prepare()` method didn't change the result.
//
// Further testing reveals that it MUST run on the main actor, before the event loop is started. Fair enought.
// So the reason it wasn't working in `init` is because although it ran first, it wasn't on the main actor.
// The more you know.
//
// UPDATE: From the the `slint::Timer` documentation (https://slint.dev/releases/1.4.1/docs/rust/slint/struct.Timer)
// > The timer can only be used in the thread that runs the Slint event loop. They will not fire if used in another thread.
// Doh!

/// Interface for the event loop.
public class EventLoop {
    /// Public singleton instance.
    public static var shared = EventLoop()
    private init() { }

    // Signal that the event loop is now running.
    private var started = AsyncChannel(Void.self)

    /// Await this value to suspend until the event loop is running.
    public static var ready: Void {
        get async { try! await shared.started.value }
    }

    /// Run a throwing closure in the Slint event loop, and await its return.
    /// - Parameter closure: Closure to run in the Slint event loop.
    /// - Returns: The result of the closure, or an error.
    /*
    @discardableResult
    public static func run<Ret>(_ closure: @escaping @Sendable () throws -> (Ret)) async -> Result<Ret, Error> {
        // Create a channel for the result.
        let channel = AsyncChannel( Result<Ret, Error>.self )

        // Create a task that will send a result, running from the Slint event loop.
        await { @SlintActor in
            channel.send( Result { try closure() } )
        }()

        // If we can get the result, return it. Otherwise return cancellation error.
        if let result = try? await channel.value {
            return result
        } else {
            return Result { throw CancellationError() }
        }
    }
    */
    
    /// Start the main event loop. This WILL block the main thread for the rest of the program!
    @MainActor
    public static func start() {
        startBeforeLoopRunning {
            shared.started.send()
        }

        print("Starting event loop.")
        slint_run_event_loop(false)
    }

    /// Stop the event loop. Currently crashes, IDK.
    @SlintActor
    public static func stop() {
        slint_quit_event_loop()
        print("Event loop has stopped.")
    }
}