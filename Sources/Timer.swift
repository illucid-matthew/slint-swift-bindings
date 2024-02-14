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
        if id != nil { }

        // Create a wraper.
        let wrapper = WrappedClosure(closure)

        let wrapperPointer = wrapper.getRetainedPointer()

        // Start the timer from the Slint event loop context.
        Task { @SlintActor [self] in
            id = slint_timer_start(
                0,                        // Assign a new ID. Docs erroneously say `-1` is the correct value. 
                mode,                           // Mode, either oneshot or repeating.
                duration,                       // Period, in milliseconds.
                WrappedClosure.invokeCallback,  // Callback to invoke the closure.
                wrapperPointer,   // Pointer to the wrapper.
                WrappedClosure.dropCallback     // Callback to release the wrapper.
            )
        }
    }
}
