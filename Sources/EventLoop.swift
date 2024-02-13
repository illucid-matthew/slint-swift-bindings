//
// EventLoop.swift
// slint
//
// Created by Matthew Taylor on 2/10/24.
//

import SlintFFI

/// Interface for the event loop.
class EventLoop {
    public static var shared = EventLoop()

    private var started = AsyncChannel(Void.self)

    private init() { }

    public var ready: Void {
        get async { try! await started.value }
    }

    @MainActor
    public func start() {
        startBeforeLoopRunning { [self] in
            started.send()
        }
        print("Starting event loop.")
        slint_run_event_loop(false)
    }

    @SlintActor
    public func stop() {
        slint_quit_event_loop()
    }
}