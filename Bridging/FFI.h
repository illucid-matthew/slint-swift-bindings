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

//
// And to import them, we also need to bring some internal types into scope.
//
#define IMPORT_SLINT_TYPE(type_name) using type_name = slint::type_name;
#define IMPORT_SLINT_TEMPLATE(template_name) template<typename T> using template_name = slint::template_name<T>;
#define IMPORT_PRIVATE_SLINT_TYPE(type_name) using type_name = slint::cbindgen_private::type_name;
#define IMPORT_PRIVATE_SLINT_TEMPLATE(template_name) template<typename T> using template_name = slint::cbindgen_private::template_name<T>;

IMPORT_SLINT_TYPE(Brush)
IMPORT_SLINT_TYPE(Rgb8Pixel)
IMPORT_SLINT_TYPE(SharedString)

IMPORT_PRIVATE_SLINT_TYPE(BitmapFont)
IMPORT_PRIVATE_SLINT_TYPE(Clipboard)
IMPORT_PRIVATE_SLINT_TYPE(CppRawHandleOpaque)
IMPORT_PRIVATE_SLINT_TYPE(IntSize)
IMPORT_PRIVATE_SLINT_TYPE(IntRect)
IMPORT_PRIVATE_SLINT_TYPE(ItemVTable)
IMPORT_PRIVATE_SLINT_TYPE(LayoutConstraintsReprC)
IMPORT_PRIVATE_SLINT_TYPE(PlatformTaskOpaque)
IMPORT_PRIVATE_SLINT_TYPE(PlatformUserData)
IMPORT_PRIVATE_SLINT_TYPE(RendererPtr)
IMPORT_PRIVATE_SLINT_TYPE(SkiaRendererOpaque)
IMPORT_PRIVATE_SLINT_TYPE(SoftwareRendererOpaque)
IMPORT_PRIVATE_SLINT_TYPE(TimerMode)
IMPORT_PRIVATE_SLINT_TYPE(WindowAdapterRcOpaque)
IMPORT_PRIVATE_SLINT_TYPE(WindowAdapterUserData)
IMPORT_PRIVATE_SLINT_TYPE(WindowProperties)

IMPORT_PRIVATE_SLINT_TEMPLATE(Point2D)


//
// Platform functionality
//
inline void slint_windowrc_init(WindowAdapterRcOpaque *out) {
    return slint::cbindgen_private::slint_windowrc_init(out);
}

inline void slint_ensure_backend() {
    return slint::cbindgen_private::slint_ensure_backend();
}

inline void slint_run_event_loop(bool quit_on_last_window_closed) {
    return slint::cbindgen_private::slint_run_event_loop(quit_on_last_window_closed);
}

inline void slint_post_event(
    void (*event)(void *user_data),
    void *user_data,
    void (*drop_user_data)(void*)
) {
    return slint::cbindgen_private::slint_post_event(event, user_data, drop_user_data);
}

inline void slint_quit_event_loop() {
    return slint::cbindgen_private::slint_quit_event_loop();
}

inline void slint_register_font_from_path(
    const WindowAdapterRcOpaque *win,
    const SharedString *path,
    SharedString *error_str
) {
    return slint::cbindgen_private::slint_register_font_from_path(win, path, error_str);
}

inline void slint_register_bitmap_font(const WindowAdapterRcOpaque *win, const BitmapFont *font_data) {
    return slint::cbindgen_private::slint_register_bitmap_font(win, font_data);
}

inline void slint_testing_init_backend() {
    return slint::cbindgen_private::slint_testing_init_backend();
}

void slint_window_properties_get_title(const WindowProperties *wp, SharedString *out) {
    return slint::cbindgen_private::slint_window_properties_get_title(wp, out);
}

void slint_window_properties_get_background(const WindowProperties *wp, Brush *out) {
    return slint::cbindgen_private::slint_window_properties_get_background(wp, out);
}

bool slint_window_properties_get_fullscreen(const WindowProperties *wp) {
    return slint::cbindgen_private::slint_window_properties_get_fullscreen(wp);
}

LayoutConstraintsReprC slint_window_properties_get_layout_constraints(const WindowProperties *wp) {
    return slint::cbindgen_private::slint_window_properties_get_layout_constraints(wp);
}

void slint_window_adapter_new(
    WindowAdapterUserData user_data,
    void (*drop)(WindowAdapterUserData),
    RendererPtr (*get_renderer_ref)(WindowAdapterUserData),
    void (*set_visible)(WindowAdapterUserData, bool),
    void (*request_redraw)(WindowAdapterUserData),
    IntSize (*size)(WindowAdapterUserData),
    void (*set_size)(WindowAdapterUserData, IntSize),
    void (*update_window_properties)(WindowAdapterUserData, const WindowProperties*),
    bool (*position)(WindowAdapterUserData, Point2D<int32_t>*),
    void (*set_position)(WindowAdapterUserData, Point2D<int32_t>),
    WindowAdapterRcOpaque *target
) {
    return slint::cbindgen_private::slint_window_adapter_new(user_data, drop, get_renderer_ref, set_visible, request_redraw, size, set_size, update_window_properties, position, set_position, target);
}

void slint_platform_register(
    PlatformUserData user_data,
    void (*drop)(PlatformUserData),
    void (*window_factory)(PlatformUserData, WindowAdapterRcOpaque*),
    uint64_t (*duration_since_start)(PlatformUserData),
    void (*set_clipboard_text)(PlatformUserData, const SharedString*, Clipboard),
    bool (*clipboard_text)(PlatformUserData, SharedString*, Clipboard),
    void (*run_event_loop)(PlatformUserData),
    void (*quit_event_loop)(PlatformUserData),
    void (*invoke_from_event_loop)(PlatformUserData, PlatformTaskOpaque)
) {
    return slint::cbindgen_private::slint_platform_register(user_data, drop, window_factory, duration_since_start, set_clipboard_text, clipboard_text, run_event_loop, quit_event_loop, invoke_from_event_loop);
}

bool slint_windowrc_has_active_animations(const WindowAdapterRcOpaque *handle) {
    return slint::cbindgen_private::slint_windowrc_has_active_animations(handle);
}

void slint_platform_update_timers_and_animations() {
    return slint::cbindgen_private::slint_platform_update_timers_and_animations();
}

uint64_t slint_platform_duration_until_next_timer_update() {
    return slint::cbindgen_private::slint_platform_duration_until_next_timer_update();
}

void slint_platform_task_drop(PlatformTaskOpaque event) {
    return slint::cbindgen_private::slint_platform_task_drop(event);
}

void slint_platform_task_run(PlatformTaskOpaque event) {
    return slint::cbindgen_private::slint_platform_task_run(event);
}

SoftwareRendererOpaque slint_software_renderer_new(uint32_t buffer_age) {
    return slint::cbindgen_private::slint_software_renderer_new(buffer_age);
}

void slint_software_renderer_drop(SoftwareRendererOpaque r) {
    return slint::cbindgen_private::slint_software_renderer_drop(r);
}

IntRect slint_software_renderer_render_rgb8(
    SoftwareRendererOpaque r,
    Rgb8Pixel *buffer,
    uintptr_t buffer_len,
    uintptr_t pixel_stride
) {
    return slint::cbindgen_private::slint_software_renderer_render_rgb8(r, buffer, buffer_len, pixel_stride);
}

IntRect slint_software_renderer_render_rgb565(
    SoftwareRendererOpaque r,
    uint16_t *buffer,
    uintptr_t buffer_len,
    uintptr_t pixel_stride
) {
    return slint::cbindgen_private::slint_software_renderer_render_rgb565(r, buffer, buffer_len, pixel_stride);
}

void slint_software_renderer_set_rendering_rotation(SoftwareRendererOpaque r, int32_t rotation) {
    return slint::cbindgen_private::slint_software_renderer_set_rendering_rotation(r, rotation);
}

RendererPtr slint_software_renderer_handle(SoftwareRendererOpaque r) {
    return slint::cbindgen_private::slint_software_renderer_handle(r);
}

CppRawHandleOpaque slint_new_raw_window_handle_win32(void *hwnd, void *hinstance) {
    return slint::cbindgen_private::slint_new_raw_window_handle_win32(hwnd, hinstance);
}

CppRawHandleOpaque slint_new_raw_window_handle_x11_xcb(uint32_t window, uint32_t visual_id, void *connection, int screen) {
    return slint::cbindgen_private::slint_new_raw_window_handle_x11_xcb(window, visual_id, connection, screen);
}

CppRawHandleOpaque slint_new_raw_window_handle_x11_xlib(unsigned long window, unsigned long visual_id, void *display, int screen) {
    return slint::cbindgen_private::slint_new_raw_window_handle_x11_xlib(window, visual_id, display, screen);
}

CppRawHandleOpaque slint_new_raw_window_handle_wayland(void *surface, void *display) {
    return slint::cbindgen_private::slint_new_raw_window_handle_wayland(surface, display);
}

CppRawHandleOpaque slint_new_raw_window_handle_appkit(void *ns_view, void *ns_window) {
    return slint::cbindgen_private::slint_new_raw_window_handle_appkit(ns_view, ns_window);
}

void slint_raw_window_handle_drop(CppRawHandleOpaque handle) {
    return slint::cbindgen_private::slint_raw_window_handle_drop(handle);
}

SkiaRendererOpaque slint_skia_renderer_new(CppRawHandleOpaque handle_opaque, IntSize size) {
    return slint::cbindgen_private::slint_skia_renderer_new(handle_opaque, size);
}

void slint_skia_renderer_drop(SkiaRendererOpaque r) {
    return slint::cbindgen_private::slint_skia_renderer_drop(r);
}

void slint_skia_renderer_render(SkiaRendererOpaque r) {
    return slint::cbindgen_private::slint_skia_renderer_render(r);
}

RendererPtr slint_skia_renderer_handle(SkiaRendererOpaque r) {
    return slint::cbindgen_private::slint_skia_renderer_handle(r);
}

//
// Timer
//
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

