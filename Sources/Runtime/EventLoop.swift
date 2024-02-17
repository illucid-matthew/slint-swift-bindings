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

// I'm running into an issue where the event loop isn't ready before we start running tasks on it, causing panics.
// So I need to somehow hold back execution until the event loop is ready. I can't use `slint_post_event`, because it checks.
// 
// But Slint timers don't. So I can manually create a timer that will run immediately once the event loop is ready.
// The only problem is that `Timer` uses the `@SlintActor` attribute, which depends on the event loop running.
//
// So we have a mini-version of timer here. Just enough to run a callback when the event loop starts.

/// Sets up a timer that runs immediately once the Slint event loop is ready.
/// This MUST ONLY be used before the event loop is started!
func startBeforeLoopRunning(_ closure: @escaping @Sendable () -> Void) {
    let wrapper = WrappedClosure(closure)
    slint_timer_singleshot(0, WrappedClosure.invokeCallback, wrapper.getRetainedPointer(), WrappedClosure.dropCallback)
}