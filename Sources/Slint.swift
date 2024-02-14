//
// Slint.swift
// slint
//
// Created by Matthew Taylor on 2/10/24.
//

/// Protocol for Slint apps.
/// 
/// Starts the Slint event loop, then enters your code.
/// 
/// ```swift
/// @main
/// struct MyApp: SlintApp {
///     static func start() async {…}
/// }
/// ```
/// 
/// To use this, implement `start()`. This function will be run at startup, in a seperate task.
/// When it returns, the Slint event loop will be closed, and the application will exit.
public protocol SlintApp {
    static func start() async throws
}

public extension SlintApp {
    static func main() async {
        // Run as detached task, so it runs independently of this task.
        Task.detached {
            // Wait for the event loop to be ready before proceding.
            print("Waiting for loop to be ready…")
            await EventLoop.shared.ready
            
            print("Loop became ready, calling start().")
            try! await start()

            // Why does this crash?
            // await EventLoop.shared.stop()
            // print("Stopped!")
        }

        // Start the event loop. This run on the main actor and block (basically) forever.
        await EventLoop.shared.start()
    }
}
