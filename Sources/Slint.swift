//
//  Slint.swift
//  slint
//
//  Created by Matthew Taylor on 2/10/24.
//

import SlintFFI

/// TEMPORARY. Protocol for Slint apps.
/// 
/// Starts the Slint event loop, then enters your code.
/// 
/// ```swift
/// @main
/// struct MyApp: SlintApp {
///     static func start() {…}
/// }
/// ```
/// 
/// To use this, implement `start()`. This function will be run at startup, in a seperate task.
/// When it returns, the Slint event loop will be closed, and the application will exit.
public protocol SlintApp {
    static func start() async throws
}

public extension SlintApp {
    /// Default implementation for `main()`, starting the event loop and concurrently running `start()`.
    static func main() async {

        // Task to run `start()`
        Task {
            // Wait for the event loop to be ready before proceding.
            print("Waiting for loop to be ready…")
            await EventLoop.ready

            print("Loop became ready, calling start().")
            try! await start()

            // Why does this crash?
            // await EventLoop.shared.stop()
            // print("Stopped!")
        }

        // Task to make the damn thing process timers
        let idleTask = Task { await idle() }

        // Start the event loop. This run on the main actor and block (basically) forever.
        await EventLoop.start()
        idleTask.cancel()
    }
}

/// Idle task. Makes Slint update its state, then sleeps for as long as Slint thinks it should.
/// Or 100ms. Whichever is shorter.
func idle() async {
    await EventLoop.ready

    while !Task.isCancelled {
        // How long until the next update?
        var durationUntilUpdate: UInt64 = 1

        await { @SlintActor in
            // Make Slint do something
            slint_platform_update_timers_and_animations()
        
            // How long until we should update again?
            durationUntilUpdate = slint_platform_duration_until_next_timer_update()
        }()

        // Wait that duration or 100ms, whichever is less.
        // Slint will set the value to UInt64.max if there is nothing waking it up.
        durationUntilUpdate = durationUntilUpdate > 100 ? 100 : durationUntilUpdate
        try! await Task.sleep(nanoseconds: durationUntilUpdate * 1_000_000)
    }
}