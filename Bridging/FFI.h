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

//
// Interpreter API
//

#include "slint_interpreter_internal.h"

// Value

IMPORT_SLINT_TYPE(Image)

IMPORT_SLINT_TEMPLATE(SharedVector)

IMPORT_PRIVATE_SLINT_TYPE(Value)
IMPORT_PRIVATE_SLINT_TYPE(ValueType)
IMPORT_PRIVATE_SLINT_TYPE(StructOpaque)
IMPORT_PRIVATE_SLINT_TYPE(StructIteratorOpaque)
IMPORT_PRIVATE_SLINT_TYPE(ModelAdaptorVTable)
IMPORT_PRIVATE_SLINT_TYPE(ModelNotifyOpaque)
IMPORT_PRIVATE_SLINT_TYPE(ComponentDefinitionOpaque)
IMPORT_PRIVATE_SLINT_TYPE(ComponentInstance)
IMPORT_PRIVATE_SLINT_TYPE(ErasedItemTreeBox)
IMPORT_PRIVATE_SLINT_TYPE(PropertyDescriptor)
IMPORT_PRIVATE_SLINT_TYPE(Diagnostic)
IMPORT_PRIVATE_SLINT_TYPE(ComponentCompilerOpaque)

IMPORT_PRIVATE_SLINT_TEMPLATE(Box)
IMPORT_PRIVATE_SLINT_TEMPLATE(Slice)

/// Construct a new Value in the given memory location
Box<Value> slint_interpreter_value_new() {
    return slint::cbindgen_private::slint_interpreter_value_new();
}

/// Construct a new Value in the given memory location
Box<Value> slint_interpreter_value_clone(const Value *other) {
    return slint::cbindgen_private::slint_interpreter_value_clone(other);
}

/// Destruct the value in that memory location
void slint_interpreter_value_destructor(Box<Value> val) {
    return slint::cbindgen_private::slint_interpreter_value_destructor(val);
}

bool slint_interpreter_value_eq(const Value *a, const Value *b) {
    return slint::cbindgen_private::slint_interpreter_value_eq(a, b);
}

/// Construct a new Value in the given memory location as string
Box<Value> slint_interpreter_value_new_string(const SharedString *str) {
    return slint::cbindgen_private::slint_interpreter_value_new_string(str);
}

/// Construct a new Value in the given memory location as double
Box<Value> slint_interpreter_value_new_double(double double_) {
    return slint::cbindgen_private::slint_interpreter_value_new_double(double_);
}

/// Construct a new Value in the given memory location as bool
Box<Value> slint_interpreter_value_new_bool(bool b) {
    return slint::cbindgen_private::slint_interpreter_value_new_bool(b);
}

/// Construct a new Value in the given memory location as array model
Box<Value> slint_interpreter_value_new_array_model(const SharedVector<Box<Value>> *a) {
    return slint::cbindgen_private::slint_interpreter_value_new_array_model(a);
}

/// Construct a new Value in the given memory location as Brush
Box<Value> slint_interpreter_value_new_brush(const Brush *brush) {
    return slint::cbindgen_private::slint_interpreter_value_new_brush(brush);
}

/// Construct a new Value in the given memory location as Struct
Box<Value> slint_interpreter_value_new_struct(const StructOpaque *struc) {
    return slint::cbindgen_private::slint_interpreter_value_new_struct(struc);
}

/// Construct a new Value in the given memory location as image
Box<Value> slint_interpreter_value_new_image(const Image *img) {
    return slint::cbindgen_private::slint_interpreter_value_new_image(img);
}

/// Construct a new Value containing a model in the given memory location
Box<Value> slint_interpreter_value_new_model(uint8_t *model, const ModelAdaptorVTable *vtable) {
    return slint::cbindgen_private::slint_interpreter_value_new_model(model, vtable);
}

ValueType slint_interpreter_value_type(const Value *val) {
    return slint::cbindgen_private::slint_interpreter_value_type(val);
}

const SharedString *slint_interpreter_value_to_string(const Value *val) {
    return slint::cbindgen_private::slint_interpreter_value_to_string(val);
}

const double *slint_interpreter_value_to_number(const Value *val) {
    return slint::cbindgen_private::slint_interpreter_value_to_number(val);
}

const bool *slint_interpreter_value_to_bool(const Value *val) {
    return slint::cbindgen_private::slint_interpreter_value_to_bool(val);
}

/// Extracts a `SharedVector<ValueOpaque>` out of the given value `val`, writes that into the
/// `out` parameter and returns true; returns false if the value does not hold an extractable
/// array.
bool slint_interpreter_value_to_array(const Box<Value> *val, SharedVector<Box<Value>> *out) {
    return slint::cbindgen_private::slint_interpreter_value_to_array(val, out);
}

const Brush *slint_interpreter_value_to_brush(const Value *val) {
    return slint::cbindgen_private::slint_interpreter_value_to_brush(val);
}

const StructOpaque *slint_interpreter_value_to_struct(const Value *val) {
    return slint::cbindgen_private::slint_interpreter_value_to_struct(val);
}

const Image *slint_interpreter_value_to_image(const Value *val) {
    return slint::cbindgen_private::slint_interpreter_value_to_image(val);
}

// Struct

/// Construct a new Struct in the given memory location
void slint_interpreter_struct_new(StructOpaque *val) {
    return slint::cbindgen_private::slint_interpreter_struct_new(val);
}

/// Construct a new Struct in the given memory location
void slint_interpreter_struct_clone(const StructOpaque *other, StructOpaque *val) {
    return slint::cbindgen_private::slint_interpreter_struct_clone(other, val);
}

/// Destruct the struct in that memory location
void slint_interpreter_struct_destructor(StructOpaque *val) {
    return slint::cbindgen_private::slint_interpreter_struct_destructor(val);
}

Value *slint_interpreter_struct_get_field(const StructOpaque *stru, Slice<uint8_t> name) {
    return slint::cbindgen_private::slint_interpreter_struct_get_field(stru, name);
}

void slint_interpreter_struct_set_field(
    StructOpaque *stru,
    Slice<uint8_t> name,
    const Value *value
) {
    return slint::cbindgen_private::slint_interpreter_struct_set_field(stru, name, value);
}

void slint_interpreter_struct_iterator_destructor(StructIteratorOpaque *val) {
    return slint::cbindgen_private::slint_interpreter_struct_iterator_destructor(val);
}

/// Advance the iterator and return the next value, or a null pointer
Value *slint_interpreter_struct_iterator_next(StructIteratorOpaque *iter, Slice<uint8_t> *k) {
    return slint::cbindgen_private::slint_interpreter_struct_iterator_next(iter, k);
}

StructIteratorOpaque slint_interpreter_struct_make_iter(const StructOpaque *stru) {
    return slint::cbindgen_private::slint_interpreter_struct_make_iter(stru);
}

// Component


/// Get a property. Returns a null pointer if the property does not exist.
Value *slint_interpreter_component_instance_get_property(
    const ErasedItemTreeBox *inst,
    Slice<uint8_t> name
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_get_property(inst, name);
}

bool slint_interpreter_component_instance_set_property(
    const ErasedItemTreeBox *inst,
    Slice<uint8_t> name,
    const Value *val
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_set_property(inst, name, val);
}

/// Invoke a callback or function. Returns raw boxed value on success and null ptr on failure.
Value *slint_interpreter_component_instance_invoke(
    const ErasedItemTreeBox *inst,
    Slice<uint8_t> name,
    Slice<Box<Value>> args
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_invoke(inst, name, args);
}

/// Set a handler for the callback.
/// The `callback` function must initialize the `ret` (the `ret` passed to the callback is initialized and is assumed initialized after the function)
bool slint_interpreter_component_instance_set_callback(
    const ErasedItemTreeBox *inst,
    Slice<uint8_t> name,
    Box<Value> (*callback)(void *user_data, Slice<Box<Value>> arg),
    void *user_data,
    void (*drop_user_data)(void*)
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_set_callback(inst, name, callback, user_data, drop_user_data);
}

/// Get a global property. Returns a raw boxed value on success; nullptr otherwise.
Value *slint_interpreter_component_instance_get_global_property(
    const ErasedItemTreeBox *inst,
    Slice<uint8_t> global,
    Slice<uint8_t> property_name
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_get_global_property(inst, global, property_name);
}

bool slint_interpreter_component_instance_set_global_property(
    const ErasedItemTreeBox *inst,
    Slice<uint8_t> global,
    Slice<uint8_t> property_name,
    const Value *val
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_set_global_property(inst, global, property_name, val);
}

/// The `callback` function must initialize the `ret` (the `ret` passed to the callback is initialized and is assumed initialized after the function)
bool slint_interpreter_component_instance_set_global_callback(
    const ErasedItemTreeBox *inst,
    Slice<uint8_t> global,
    Slice<uint8_t> name,
    Box<Value> (*callback)(void *user_data, Slice<Box<Value>> arg),
    void *user_data,
    void (*drop_user_data)(void*)
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_set_global_callback(inst, global, name, callback, user_data, drop_user_data);
}

/// Invoke a global callback or function. Returns raw boxed value on success; nullptr otherwise.
Value *slint_interpreter_component_instance_invoke_global(
    const ErasedItemTreeBox *inst,
    Slice<uint8_t> global,
    Slice<uint8_t> callable_name,
    Slice<Box<Value>> args
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_invoke_global(inst, global, callable_name, args);
}

/// Show or hide
void slint_interpreter_component_instance_show(const ErasedItemTreeBox *inst, bool is_visible){
    return slint::cbindgen_private::slint_interpreter_component_instance_show(inst, is_visible);
}

/// Return a window for the component
///
/// The out pointer must be uninitialized and must be destroyed with
/// slint_windowrc_drop after usage
void slint_interpreter_component_instance_window(
    const ErasedItemTreeBox *inst,
    const WindowAdapterRcOpaque **out
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_window(inst, out);
}

/// Instantiate an instance from a definition.
///
/// The `out` must be uninitialized and is going to be initialized after the call
/// and need to be destroyed with slint_interpreter_component_instance_destructor
void slint_interpreter_component_instance_create(
    const ComponentDefinitionOpaque *def,
    ComponentInstance *out
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_create(def, out);
}

void slint_interpreter_component_instance_component_definition(
    const ErasedItemTreeBox *inst,
    ComponentDefinitionOpaque *component_definition_ptr
) {
    return slint::cbindgen_private::slint_interpreter_component_instance_component_definition(inst, component_definition_ptr);
}

/// Construct a new ModelNotifyNotify in the given memory region
void slint_interpreter_model_notify_new(ModelNotifyOpaque *val) {
    return slint::cbindgen_private::slint_interpreter_model_notify_new(val);
}

/// Destruct the value in that memory location
void slint_interpreter_model_notify_destructor(ModelNotifyOpaque *val) {
    return slint::cbindgen_private::slint_interpreter_model_notify_destructor(val);
}

void slint_interpreter_model_notify_row_changed(const ModelNotifyOpaque *notify, uintptr_t row) {
    return slint::cbindgen_private::slint_interpreter_model_notify_row_changed(notify, row);
}

void slint_interpreter_model_notify_row_added(
    const ModelNotifyOpaque *notify,
    uintptr_t row,
    uintptr_t count
) {
    return slint::cbindgen_private::slint_interpreter_model_notify_row_added(notify, row, count);
}

void slint_interpreter_model_notify_reset(const ModelNotifyOpaque *notify) {
    return slint::cbindgen_private::slint_interpreter_model_notify_reset(notify);
}

void slint_interpreter_model_notify_row_removed(
    const ModelNotifyOpaque *notify,
    uintptr_t row,
    uintptr_t count
) {
    return slint::cbindgen_private::slint_interpreter_model_notify_row_removed(notify, row, count);
}

void slint_interpreter_component_compiler_new(ComponentCompilerOpaque *compiler) {
    return slint::cbindgen_private::slint_interpreter_component_compiler_new(compiler);
}

void slint_interpreter_component_compiler_destructor(ComponentCompilerOpaque *compiler) {
    return slint::cbindgen_private::slint_interpreter_component_compiler_destructor(compiler);
}

void slint_interpreter_component_compiler_set_include_paths(
    ComponentCompilerOpaque *compiler,
    const SharedVector<SharedString> *paths
) {
    return slint::cbindgen_private::slint_interpreter_component_compiler_set_include_paths(compiler, paths);
}

void slint_interpreter_component_compiler_set_style(
    ComponentCompilerOpaque *compiler,
    Slice<uint8_t> style
) {
    return slint::cbindgen_private::slint_interpreter_component_compiler_set_style(compiler, style);
}

void slint_interpreter_component_compiler_get_style(
    const ComponentCompilerOpaque *compiler,
    SharedString *style_out
) {
    return slint::cbindgen_private::slint_interpreter_component_compiler_get_style(compiler, style_out);
}

void slint_interpreter_component_compiler_get_include_paths(
    const ComponentCompilerOpaque *compiler,
    SharedVector<SharedString> *paths
) {
    return slint::cbindgen_private::slint_interpreter_component_compiler_get_include_paths(compiler, paths);
}

void slint_interpreter_component_compiler_get_diagnostics(
    const ComponentCompilerOpaque *compiler,
    SharedVector<Diagnostic> *out_diags
) {
    return slint::cbindgen_private::slint_interpreter_component_compiler_get_diagnostics(compiler, out_diags);
}

bool slint_interpreter_component_compiler_build_from_source(
    ComponentCompilerOpaque *compiler,
    Slice<uint8_t> source_code,
    Slice<uint8_t> path,
    ComponentDefinitionOpaque *component_definition_ptr
) {
    return slint::cbindgen_private::slint_interpreter_component_compiler_build_from_source(compiler, source_code, path, component_definition_ptr);
}

bool slint_interpreter_component_compiler_build_from_path(
    ComponentCompilerOpaque *compiler,
    Slice<uint8_t> path,
    ComponentDefinitionOpaque *component_definition_ptr
) {
    return slint::cbindgen_private::slint_interpreter_component_compiler_build_from_path(compiler, path, component_definition_ptr);
}

/// Construct a new Value in the given memory location
void slint_interpreter_component_definition_clone(
    const ComponentDefinitionOpaque *other,
    ComponentDefinitionOpaque *def
) {
    return slint::cbindgen_private::slint_interpreter_component_definition_clone(other, def);
}

/// Destruct the component definition in that memory location
void slint_interpreter_component_definition_destructor(ComponentDefinitionOpaque *val) {
    return slint::cbindgen_private::slint_interpreter_component_definition_destructor(val);
}

/// Returns the list of properties of the component the component definition describes
void slint_interpreter_component_definition_properties(
    const ComponentDefinitionOpaque *def,
    SharedVector<PropertyDescriptor> *props
) {
    return slint::cbindgen_private::slint_interpreter_component_definition_properties(def, props);
}

/// Returns the list of callback names of the component the component definition describes
void slint_interpreter_component_definition_callbacks(
    const ComponentDefinitionOpaque *def,
    SharedVector<SharedString> *callbacks
) {
    return slint::cbindgen_private::slint_interpreter_component_definition_callbacks(def, callbacks);
}

/// Return the name of the component definition
void slint_interpreter_component_definition_name(
    const ComponentDefinitionOpaque *def,
    SharedString *name
) {
    return slint::cbindgen_private::slint_interpreter_component_definition_name(def, name);
}

/// Returns a vector of strings with the names of all exported global singletons.
void slint_interpreter_component_definition_globals(
    const ComponentDefinitionOpaque *def,
    SharedVector<SharedString> *names
) {
    return slint::cbindgen_private::slint_interpreter_component_definition_globals(def, names);
}

/// Returns a vector of the property descriptors of the properties of the specified publicly exported global
/// singleton. Returns true if a global exists under the specified name; false otherwise.
bool slint_interpreter_component_definition_global_properties(
    const ComponentDefinitionOpaque *def,
    Slice<uint8_t> global_name,
    SharedVector<PropertyDescriptor> *properties
) {
    return slint::cbindgen_private::slint_interpreter_component_definition_global_properties(def, global_name, properties);
}

/// Returns a vector of the names of the callbacks of the specified publicly exported global
/// singleton. Returns true if a global exists under the specified name; false otherwise.
bool slint_interpreter_component_definition_global_callbacks(
    const ComponentDefinitionOpaque *def,
    Slice<uint8_t> global_name,
    SharedVector<SharedString> *names
) {
    return slint::cbindgen_private::slint_interpreter_component_definition_global_callbacks(def, global_name, names);
}
