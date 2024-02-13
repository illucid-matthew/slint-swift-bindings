//
//  Timer.swift
//  Slint
//
//  Created by Matthew Taylor on 2/8/24.
//

import SlintFFI

/// Wrapper around a timer callback.
class GenericClosureWrapper {
    private let _invoke: () -> Void
    init(_ closure: @escaping () -> Void) { _invoke = closure }
    func invoke() { _invoke() }
}

/// Timer that can invoke a callback, once or periodically.
public class Timer {
    public init() {

    }

    /// Type alias for the timer callback.
    fileprivate typealias TimerCallback = (@convention(c) (UnsafeMutableRawPointer?) -> Void)?
    
    /// Type alias for the `drop_user_data` callback.
    fileprivate typealias DropUserDataCallback = (@convention(c) (UnsafeMutableRawPointer?) -> Void)?

    /// Timer callback. Calls the wrapped closure.
    fileprivate static let timerCallback: TimerCallback = { userDataPtr in
        print("Greetings from `timerCallback`")
        let wrapper = Unmanaged<GenericClosureWrapper>.fromOpaque(userDataPtr!).takeUnretainedValue()
        wrapper.invoke()
    }

    /// Drop user data callback. Releases the wrapper.
    fileprivate static let dropUserDataCallback: DropUserDataCallback = { userDataPtr in
        print("Greetings from `dropUserDataCallback`")
        _ = Unmanaged<GenericClosureWrapper>.fromOpaque(userDataPtr!).takeRetainedValue()
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
func startBeforeLoopRunning(_ closure: @escaping () -> Void) {
    let wrapper = GenericClosureWrapper {
        print("Greetings from `startBeforeLoopRunning`")
        closure()
    }
    let wrapperPtr = Unmanaged<GenericClosureWrapper>.passRetained(wrapper).toOpaque()
    print("Starting timer…")
    _ = slint_timer_start(0, TimerMode.SingleShot, 0, Timer.timerCallback, wrapperPtr, Timer.dropUserDataCallback)
}
