//
// EventLoop.swift
// slint
//
// Created by Matthew Taylor on 2/10/24.
//

// This file is temporary. It only exists to expose some low-leve functions for testing.

import SlintFFI

// 🤓 ERHM ACHUALLY these functions should be @MainActor, cuz the API isn't threadsafe and Slint will panic if called from another thread.
// But that's a barrel of balls, and without doing any async that's not really a concern at the moment.

public func StartEventLoop() {
    slint_run_event_loop(false)
}

public func StopEventLoop() {
    slint_quit_event_loop()
}