#pragma once

//
// Include the overarching FFI header, which includes everything in the core library.
//
#include "slint_internal.h"

// The event loop is part of the platform, not core library.
#include "slint_platform_internal.h"

//
// But we're not done yet.
//
// FFI functions are declared as `extern "C"`.
// Swift won't import those, so we need to wrap them manually.
//

// Minimal event loop stuff
inline void slint_run_event_loop(bool quit_on_last_window_closed) {
    return slint::cbindgen_private::slint_run_event_loop(quit_on_last_window_closed);
}

inline void slint_quit_event_loop() {
    return slint::cbindgen_private::slint_quit_event_loop();
}

// Timer stuff
using TimerMode = slint::cbindgen_private::TimerMode;

uintptr_t slint_timer_start(uintptr_t id,
                            TimerMode mode,
                            uint64_t duration,
                            void (*callback)(void*),
                            void *user_data,
                            void (*drop_user_data)(void*)) {

    return slint::cbindgen_private::slint_timer_start(id, mode, duration, callback, user_data, drop_user_data);
}

void slint_timer_singleshot(uint64_t delay,
                            void (*callback)(void*),
                            void *user_data,
                            void (*drop_user_data)(void*)) {
                                
    return slint::cbindgen_private::slint_timer_singleshot(delay, callback, user_data, drop_user_data);
}

void slint_timer_destroy(uintptr_t id) {
    return slint::cbindgen_private::slint_timer_destroy(id);
}

void slint_timer_stop(uintptr_t id) {
    return slint::cbindgen_private::slint_timer_stop(id);
}

void slint_timer_restart(uintptr_t id) {
    return slint::cbindgen_private::slint_timer_restart(id);
}

bool slint_timer_running(uintptr_t id) {
    return slint::cbindgen_private::slint_timer_running(id);
}
