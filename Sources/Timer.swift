//
//  Timer.swift
//  Slint
//
//  Created by Matthew Taylor on 2/8/24.
//

import SlintFFI

/// Wrapper around a timer callback.
fileprivate class TimerCallbackWrapper {
    // Wrapped closure.
    private let _invoke: () -> Void
    init(_ closure: @escaping () -> Void) { _invoke = closure }
    func invoke() { _invoke() }
}

/// Timer that can invoke a callback, once or periodically.
@MainActor
class Timer {
    /// True if the timer is currently running.
    var running: Bool {
        if let id = id { slint_timer_running(id) }
        else { false }
    }
    
    /// Start a one-shot timer, executing a closure after `period` milliseconds.
    func run(after duration: UInt64, _ closure: @escaping () -> ()) {
        start(mode: .SingleShot, duration: duration, closure: closure)
    }
    
    /// Start a repeating timer, executing a closure every `period` milliseconds.
    func run(every period: UInt64, _ closure: @escaping () -> ()) {
        start(mode: .Repeated, duration: period, closure: closure)
    }
    
    /// Stop a timer. Does nothing if the timer isn't running.
    func stop() {
        // Only run if there is an ID set, meaning a timer was created at some point.
        if let id = id { slint_timer_stop(id) }
    }
    
    /// Restart a timer. ‼️ Only applies to repeating timers!
    func restart() {
        if let id = id { slint_timer_restart(id) }
    }
    
    /// ID assigned to the timer by Slint. If the timer hasn't been started, the value is `nil`.
    private var id: UInt? = nil
    
    private func destroy() {
        // Destroy the timer
        if let id = id { slint_timer_destroy(id) }
        self.id = nil
    }
    
    /// Start the timer.
    private func start(mode: TimerMode, duration: UInt64, closure: @escaping () -> Void) {
        // If there's already an existing timer, stop and destroy.
        if id != nil {
            stop()
            destroy()
        }
        
        // Create a wrapper
        let wrapper = TimerCallbackWrapper(closure)
        
        // Perform an unbalanced retain and get an opaque pointer
        let wrapperPtr = Unmanaged<TimerCallbackWrapper>.passRetained(wrapper).toOpaque()
        
        // Create the timer
        id = slint_timer_start(
            0,    // 0 means "return a new ID"
            mode,
            duration,
            timerCallback,
            wrapperPtr,
            dropUserDataCallback
        )
    }
    
    /// Deinitializer.
    deinit {
        // We can't call destroy() from the deinitializer, because the deinitializer
        // is in a synchronous nonisolated context, and destroy() is an actor-isolated method.
        if let id = id { slint_timer_destroy(id) }
    }
    
    /// Type alias for the timer callback.
    private typealias TimerCallback = (@convention(c) (UnsafeMutableRawPointer?) -> Void)?
    
    /// Type alias for the `drop_user_data` callback.
    private typealias DropUserDataCallback = (@convention(c) (UnsafeMutableRawPointer?) -> Void)?
    
    /// Timer callback. Calls the wrapped closure.
    private let timerCallback: TimerCallback =
    { userDataPtr in
        // Convert to instance reference
        let wrapper = userDataPtr!.assumingMemoryBound(to: TimerCallbackWrapper.self).pointee
        // Invoke
        wrapper.invoke()
    }
    
    /// Drop user data callback. Releases the wrapper.
    private let dropUserDataCallback: DropUserDataCallback =
    { userDataPtr in
        // Convert the raw pointer to an unmanaged reference and release
        _ = Unmanaged<TimerCallbackWrapper>.fromOpaque(userDataPtr!).takeRetainedValue()
    }
}
