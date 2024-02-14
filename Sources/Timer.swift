//
//  Timer.swift
//  Slint
//
//  Created by Matthew Taylor on 2/8/24.
//

import SlintFFI

/// Timer that can invoke a callback, once or periodically.
public class Timer {
    /// Timer ID. Used a handle for the Slint FFI. 
    private var id: UInt?
    /// Initializer.
    public init() { }
    
    /// Sets up a single-shot timer to run after a set number of milliseconds.
    /// - Parameters:
    ///   - duration: Milliseconds until the closure should be called.
    ///   - closure: The closure to call.
    public func willRun(after duration: UInt64, _ closure: @escaping @Sendable () -> Void) {
        start(mode: TimerMode.SingleShot, duration: duration, closure: closure)
    }

    /// Sets up a repeating timer to run periodically after a set number of milliseconds.
    /// - Parameters:
    ///   - duration: Milliseconds until the closure should be called.
    ///   - closure: The closure to call.
    public func willRun(every duration: UInt64, _ closure: @escaping @Sendable () -> Void) {
        start(mode: TimerMode.Repeated, duration: duration, closure: closure)
    }

    public var running: Bool {
        guard id != nil else { return false }
        
        return false
    }

    /// Internal function, starts timer from the Slint event loop context.
    private func start(mode: TimerMode, duration: UInt64, closure: @escaping @Sendable () -> Void) {
        // Clean up existing timer, if any.
        if id != nil {

        }

        // Create a wraper.
        let wrapperPointer = WrappedClosure(closure).getRetainedPointer()

        print("About to start a task to create a timer\t\t\(String(describing: wrapperPointer))")

        // Start the timer from the Slint event loop context.
        // Task { @SlintActor [self] in
            id = slint_timer_start(
                0,                        // Assign a new ID. Docs erroneously say `-1` is the correct value. 
                mode,                           // Mode, either oneshot or repeating.
                duration,                       // Period, in milliseconds.
                WrappedClosure.invokeCallback,  // Callback to invoke the closure.
                wrapperPointer,   // Pointer to the wrapper.
                WrappedClosure.dropCallback     // Callback to release the wrapper.
            )
            print("Timer set up (ID: \(id!))")
        // }
    }
}

// I'm running into an issue where the event loop isn't ready before we start running tasks on it, causing panics.
// So I need to somehow hold back execution until the event loop is ready. I can't use `slint_post_event`, because it checks.
// 
// But Slint timers don't. So I can manually create a timer that will run immediately once the event loop is ready.
// The only problem is that `Timer` uses the `@SlintActor` attribute, which depends on the event loop running.
//
// So we have a mini-version of timer here. Just enough to run a callback when the event loop starts.
//
// Additionally, Swift balks when the same FFI call is made in different files. So this has to live here.

/// Sets up a timer that runs immediately once the Slint event loop is ready.
/// This MUST ONLY be used before the event loop is started!
func startBeforeLoopRunning(_ closure: @escaping @Sendable () -> Void) {
    let wrapper = WrappedClosure(closure)
    slint_timer_singleshot(0, WrappedClosure.invokeCallback, wrapper.getRetainedPointer(), WrappedClosure.dropCallback)
}
