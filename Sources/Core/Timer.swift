//
//  Timer.swift
//  Slint
//
//  Created by Matthew Taylor on 2/8/24.
//

import SlintFFI

/// Timer that can invoke a callback, once or periodically.
/// 
/// Note: This will leak if you call `willRun(_:_:)`, but never call 
@SlintActor
public class SlintTimer {
    /// Timer ID. Used a handle for the Slint FFI. 
    private var id: UInt?

    /// Initializer. Nonisolated because it doesn't do anything, so it doesn't need to be isolated.
    nonisolated public init() { }

    /// Deinitializer
    deinit {
        // If the timer exists, destroy it.
        // This crashes if the timer is destroyed immediately after being created, I suspect.
        if let id {
            slint_timer_destroy(id)
        }
    }
    
    /// Sets up a single-shot timer to run after a set number of milliseconds.
    /// - Parameters:
    ///   - duration: Milliseconds until the closure should be called.
    ///   - closure: The closure to call.
    public func willRun(after duration: UInt64, _ closure: @SlintActor @escaping @Sendable () -> Void) {
        start(mode: TimerMode.SingleShot, duration: duration, closure: closure)
    }

    /// Sets up a repeating timer to run periodically after a set number of milliseconds.
    /// - Parameters:
    ///   - duration: Milliseconds until the closure should be called.
    ///   - closure: The closure to call.
    public func willRun(every duration: UInt64, _ closure: @SlintActor @escaping @Sendable () -> Void) {
        start(mode: TimerMode.Repeated, duration: duration, closure: closure)
    }

    /// Stop the current timer, if running. Otherwise does nothing.
    /// 
    /// Note: I also have found that stopping a timer from another timer's closure doesn't work.
    public func stop() {
        if let id {
            // Actually, it seems to be doing nothing, regardless.
            print("Note: stopped timer \(id)")
            slint_timer_stop(id)
            print("Note: \(id) running? \(running)")
        }
    }

    /// Drop the current timer, if it exists.
    public func drop() {
        if let id {
            slint_timer_destroy(id)
            self.id = nil
        }
    }

    /// Restart the current timer, if stopped. Otherwise does nothing.
    public func restart() {
        if let id { slint_timer_restart(id) }
    }

    /// True if the timer is currently running. False otherwise.
    public var running: Bool {
        if let id {
            return slint_timer_running(id)
        } else {
            return false
        }
    }

    /// Internal function, starts timer from the Slint event loop context.
    private func start(mode: TimerMode, duration: UInt64, closure: @SlintActor @escaping @Sendable () -> Void) {
        // Create a wraper, specifically retaining this object until the timer is dropped by Slint.
        let wrapper = WrappedClosure {
            withExtendedLifetime(self) { closure() }
        }

        id = slint_timer_start(
            id ?? 0,                        // Assign a new ID if we don't already have one. Docs erroneously say `-1` is the correct value. 
            mode,                           // Mode, either oneshot or repeating.
            duration,                       // Period, in milliseconds.
            WrappedClosure.invokeCallback,  // Callback to invoke the closure.
            wrapper.getRetainedPointer(),   // Pointer to the wrapper.
            WrappedClosure.dropCallback     // Callback to release the wrapper.
        )

        print("Created timer \(id ?? UInt.max)")
    }
}
