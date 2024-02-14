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
        let idleTask = Task {
            await EventLoop.ready

            while !Task.isCancelled {
                // Sleep for 1ms
                try! await Task.sleep(nanoseconds: 1_000_000)

                // Make Slint do something
                await { @SlintActor in
                    slint_platform_update_timers_and_animations()
                }()
            }
        }

        // Start the event loop. This run on the main actor and block (basically) forever.
        await EventLoop.start()
        idleTask.cancel()
    }
}