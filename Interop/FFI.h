#pragma once

// Include this. The FFI headers reference std::string stuff without ever including it.
#include <iostream>
#include <thread>
#include <string>

// Pointer event enum and key codes.
#include "slint_enums.h"

// Some structures and enum types, meant for public use.
#include "slint_generated_public.h"

// Some private structures.
#include "slint_builtin_structs_internal.h"

// Timer functionality.
#include "slint_timer_internal.h"

// #include "slint_platform_internal.h"

void test() {
    std::cout << "Hello from C++!" << std::endl;
}

// Swift won't import `extern "C"` declarations from C++ modules.
// I don't want to completely rewrite the headers, so the easiest thing would seem to be
// writing thin, inline wrappers that call the C functions.


using slint::cbindgen_private::TimerMode;

inline uintptr_t slint_timer_start(uintptr_t id,
                            TimerMode mode,
                            uint64_t duration,
                            void (*callback)(void*),
                            void *user_data,
                            void (*drop_user_data)(void*)) {

    return slint::cbindgen_private::slint_timer_start(id, mode, duration, callback, user_data, drop_user_data);
}

inline void slint_timer_singleshot(uint64_t delay,
                            void (*callback)(void*),
                            void *user_data,
                            void (*drop_user_data)(void*)) {
    slint::cbindgen_private::slint_timer_singleshot(delay, callback, user_data, drop_user_data);
}

inline void slint_timer_destroy(uintptr_t id) {
    slint::cbindgen_private::slint_timer_destroy(id);
}

inline void slint_timer_stop(uintptr_t id) {
    slint::cbindgen_private::slint_timer_stop(id);
}

inline void slint_timer_restart(uintptr_t id) {
    slint::cbindgen_private::slint_timer_restart(id);
}

inline bool slint_timer_running(uintptr_t id) {
    return slint::cbindgen_private::slint_timer_running(id);
}

/*
inline void assert_main_thread()
{
#ifndef SLINT_FEATURE_FREESTANDING
#    ifndef NDEBUG
    static auto main_thread_id = std::this_thread::get_id();
    if (main_thread_id != std::this_thread::get_id()) {
        std::cerr << "A function that should be only called from the main thread was called from a "
                     "thread."
                  << std::endl;
        std::cerr << "Most API should be called from the main thread. When using thread one must "
                     "use slint::invoke_from_event_loop."
                  << std::endl;
        std::abort();
    }
#    endif
#endif
}

void slint_run_event_loop(bool quit_on_last_window_closed) {
    slint::cbindgen_private::slint_run_event_loop(quit_on_last_window_closed);
}

/// Enum for the event loop mode parameter of the slint::run_event_loop() function.
/// It is used to determine when the event loop quits.
enum class EventLoopMode {
    /// The event loop will quit when the last window is closed
    /// or when slint::quit_event_loop() is called.
    QuitOnLastWindowClosed,

    /// The event loop will keep running until slint::quit_event_loop() is called,
    /// even when all windows are closed.
    RunUntilQuit
};

/// Enters the main event loop. This is necessary in order to receive
/// events from the windowing system in order to render to the screen
/// and react to user input.
///
/// The mode parameter determines the behavior of the event loop when all windows are closed.
/// By default, it is set to QuitOnLastWindowClose, which means the event loop will
/// quit when the last window is closed.
inline void run_event_loop(EventLoopMode mode = EventLoopMode::QuitOnLastWindowClosed)
{
    assert_main_thread();
    cbindgen_private::slint_run_event_loop(mode == EventLoopMode::QuitOnLastWindowClosed);
}

*/