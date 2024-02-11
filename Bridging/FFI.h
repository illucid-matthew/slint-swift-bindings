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

inline void slint_run_event_loop(bool quit_on_last_window_closed) {
    return slint::cbindgen_private::slint_run_event_loop(quit_on_last_window_closed);
}

inline void slint_quit_event_loop() {
    return slint::cbindgen_private::slint_quit_event_loop();
}