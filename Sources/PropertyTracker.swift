//
// PropertyTracker.swift
// slint
//
// Created by Matthew Taylor on 2/6/24.
//

//
// 🚧 Mock interface 🚧
//
struct PropertyTrackerOpaque { }

func slint_property_tracker_init(_ handle: UnsafeMutablePointer<PropertyTrackerOpaque>) { }
func slint_property_tracker_evaluate(
    _ handle: UnsafePointer<PropertyTrackerOpaque>,
    _ callback: @convention(c) (UnsafeMutableRawPointer) -> Void,
    _ userData: UnsafeMutableRawPointer
) { }
func slint_property_tracker_evaluate_as_dependency_root(
    _ handle: UnsafePointer<PropertyTrackerOpaque>,
    _ callback: @convention(c) (UnsafeMutableRawPointer) -> Void,
    _ userData: UnsafeMutableRawPointer
) { }
func slint_property_tracker_is_dirty(_ handle: UnsafePointer<PropertyTrackerOpaque>) -> CBool { false }
func slint_property_tracker_drop(_ handle: UnsafeMutablePointer<PropertyTrackerOpaque>) { }
//
// 🚧 END Mock interface 🚧
//

/// Wrapper for a tracker clousre. Extremely simple, just exists so the closure can capture values.
fileprivate class PropertyTrackerWrapper {
    private let _callback: () -> Void
    init(_ callback: @escaping () -> Void) { _callback = callback }
    func invoke() { _callback() }
}

/// Property tracker allows you to keep track of if a property, or any dependencies, have changed.
class PropertyTracker {
    private var handle = PropertyTrackerOpaque()
    private var handleUnsafe: UnsafePointer<PropertyTrackerOpaque> {
        withUnsafePointer(to: handle) { $0 }
    }

    init() {
        withUnsafeMutablePointer(to: &handle) { handleMut in
            slint_property_tracker_init(handleMut)
        }
    }

    deinit {
        withUnsafeMutablePointer(to: &handle) { handleMut in
            slint_property_tracker_drop(handleMut)
        }
    }

    /// Has the property or its dependencies changed?
    var dirty: Bool { slint_property_tracker_is_dirty(handleUnsafe) }

    /// Type alias for a tracker callback
    private typealias TrackerCallback = @convention(c) (UnsafeMutableRawPointer) -> ()

    /// Closure for tracker callback.
    private let trackerCallback: TrackerCallback = { userDataPtr in
        let wrapper = userDataPtr.assumingMemoryBound(to: PropertyTrackerWrapper.self).pointee
        wrapper.invoke()
    }

    /// Evaluate the callback and track any properties that were accessed.
    @MainActor
    func evalute(asRoot: Bool = false, _ callback: @escaping () -> Void) {
        var wrapper = PropertyTrackerWrapper(callback)

        // We don't have to worry about lifetime, because the function will block until its done.
        withUnsafeMutablePointer(to: &wrapper) { wrapperUnsafe in
            let wrapperPtr = UnsafeMutableRawPointer(wrapperUnsafe)

            if asRoot {
                slint_property_tracker_evaluate_as_dependency_root(
                    handleUnsafe,
                    trackerCallback,
                    wrapperPtr
                )
            } else {
                slint_property_tracker_evaluate(
                    handleUnsafe,
                    trackerCallback,
                    wrapperPtr
                )
            }
        }
    }

    /// Evaluate the callback and track any properties that were accessed, returning the value.
    @MainActor
    func evaluate<Ret>(asRoot: Bool = false, _ callback: @escaping () -> Ret) -> Ret {
        // The result needs to be optional, otherwise Swift will complain that we're using it before it's initialized.
        // And we can't initialize it, because not all types have a default initializer.
        var returnValue: Ret? = nil
        evalute(asRoot: asRoot) {
            returnValue = callback()
        }
        // This is okay, because the closure will assign a return value.
        return returnValue!
    }
}
