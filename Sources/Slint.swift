//
//  Slint.swift
//  slint
//
//  Created by Matthew Taylor on 2/10/24.
//

import SlintFFI

public protocol OldSlintApp {
    /// Runs before the event loop has started.
    static func start() async
}

public extension OldSlintApp {
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

/// Protocol for Slint applications.
/// 
/// Usage:
/// ```swift
/// @main
/// struct MyApp: SlintApp {
///     static func start() {
///         …
///     }
/// }
/// ```
/// 
/// You provide an implementation for `start()`, which sets up your UI.
/// After it returns, the event loop will be started and run.
public protocol SlintApp {
    /// Setup UI before the main event loop is running.
    /// 
    /// Note: `async` is optional. Synchronous functions can fulfill asynchronous requirements.
    @SlintActor static func start() async
}

public extension SlintApp {
    /// Implementation for `main()`.
    @MainActor
    static func main() async {
        // Switch Slint actor into 'main actor mode'
        SwitchToMainActorExecutor()

        // Execute start
        await Self.start()

        // Setup idle task.
        let idleTask = Task.detached { await idle() }

        // Switch Slint actor into 'event loop mode'
        SwitchToEventLoopExecutor()

        // Start the event loop
        EventLoop.start()

        // If that returns, cancel the idle task.
        idleTask.cancel()
    }
}