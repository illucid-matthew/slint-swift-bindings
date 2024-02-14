//
// EventLoop.swift
// slint
//
// Created by Matthew Taylor on 2/10/24.
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

/// Interface for the event loop.
public class EventLoop {
    /// Public singleton instance.
    public static var shared = EventLoop()
    private init() { }

    private var started = AsyncChannel(Void.self)

    /// Await this value to suspend until the event loop is running.
    public var ready: Void {
        get async { try! await started.value }
    }

    /// Run a closure in the Slint event loop, blocking until it returns.
    public static func run<Ret>(_ closure: @escaping @Sendable () -> (Ret)) async -> Ret {
        let channel = AsyncChannel(Ret.self)
        Task { @SlintActor in
            channel.send(closure())
        }
        return try! await channel.value
    }

    /// Start the main event loop. This WILL block the main thread for the rest of the program!
    @MainActor
    public func start() { 
        print("Setting up timer")
        startBeforeLoopRunning { [self] in
            started.send()
        }

        print("Starting event loop.")
        slint_run_event_loop(false)
    }

    /// Stop the event loop. Currently crashes, IDK.
    @SlintActor
    public func stop() {
        slint_quit_event_loop()
        print("Event loop has stopped.")
    }
}