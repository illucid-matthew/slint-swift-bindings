//
// Property.swift
// slint
//
// Created by Matthew Taylor on 2/6/24.
//

//
// 🚧 Mock interface 🚧
//
struct PropertyWrapperOpaque {
    var _0: Int = 0
}
struct StateInfo { }
struct SlintColor { }
struct SlintBrush { }
struct PropertyAnimation { }

func slint_property_init(_ out: UnsafeMutablePointer<PropertyWrapperOpaque>) { }
func slint_property_update(_ handle: UnsafePointer<PropertyWrapperOpaque>, _ val: UnsafeMutableRawPointer) { }
func slint_property_set_changed(_ handle: UnsafePointer<PropertyWrapperOpaque>, _ value: UnsafeRawPointer) { }
func slint_property_set_binding(
    _ handle: UnsafePointer<PropertyWrapperOpaque>,
    _ binding: @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Void,
    _ userData: UnsafeMutableRawPointer,
    _ dropUserData: @convention(c) (UnsafeMutableRawPointer) -> Void,
    _ interceptSet: (@convention(c) (UnsafeMutableRawPointer, UnsafeRawPointer) -> CBool)?,
    _ interceptSetBindng: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> CBool)?
) { }
func slint_property_set_binding_internal(
    _ handle: UnsafePointer<PropertyWrapperOpaque>,
    _ binding: UnsafeMutableRawPointer
) { }
func slint_property_is_dirty(_ handle: UnsafePointer<PropertyWrapperOpaque>) -> CBool { return false }
func slint_property_mark_dirty(_ handle: UnsafePointer<PropertyWrapperOpaque>) { }
func slint_property_drop( _ handle: UnsafePointer<PropertyWrapperOpaque>) { }
func slint_property_set_animated_value_int(
    _ handle: UnsafePointer<PropertyWrapperOpaque>,
    _ from: Int32,
    _ to: Int32,
    _ animationData: UnsafePointer<PropertyAnimation>
) { }
func slint_property_set_animated_value_float(
    _ handle: UnsafePointer<PropertyWrapperOpaque>,
    _ from: CFloat,
    _ to: CFloat,
    _ animationData: UnsafePointer<PropertyAnimation>
) { }
func slint_property_set_animated_value_color(
    _ handle: UnsafePointer<PropertyWrapperOpaque>,
    _ from: SlintColor,
    _ to: SlintColor,
    _ animationData: UnsafePointer<PropertyAnimation>
) { }
func slint_property_set_animated_binding_int(
    _ handle: UnsafePointer<PropertyWrapperOpaque>,
    _ binding: @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Void,
    _ userData: UnsafeMutableRawPointer,
    _ dropUserData: @convention(c) (UnsafeMutableRawPointer) -> Void,
    _ animationData: UnsafePointer<PropertyAnimation>,
    _ transitionData: UnsafeRawPointer?
) { }
func slint_property_set_animated_binding_float(
    _ handle: UnsafePointer<PropertyWrapperOpaque>,
    _ binding: @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Void,
    _ userData: UnsafeMutableRawPointer,
    _ dropUserData: @convention(c) (UnsafeMutableRawPointer) -> Void,
    _ animationData: UnsafePointer<PropertyAnimation>,
    _ transitionData: UnsafeRawPointer?
) { }
func slint_property_set_animated_binding_color(
    _ handle: UnsafePointer<PropertyWrapperOpaque>,
    _ binding: @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Void,
    _ userData: UnsafeMutableRawPointer,
    _ dropUserData: @convention(c) (UnsafeMutableRawPointer) -> Void,
    _ animationData: UnsafePointer<PropertyAnimation>,
    _ transitionData: UnsafeRawPointer?
) { }
func slint_property_set_animated_binding_brush(
    _ handle: UnsafePointer<PropertyWrapperOpaque>,
    _ binding: @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Void,
    _ userData: UnsafeMutableRawPointer,
    _ dropUserData: @convention(c) (UnsafeMutableRawPointer) -> Void,
    _ animationData: UnsafePointer<PropertyAnimation>,
    _ transitionData: UnsafeRawPointer?
) { }
func slint_property_set_state_binding(
    _ handle: UnsafePointer<PropertyWrapperOpaque>,
    _ binding: @convention(c) (UnsafeMutableRawPointer) -> Int32,
    _ userData: UnsafeMutableRawPointer,
    _ dropUserData: @convention(c) (UnsafeMutableRawPointer) -> Void
) { }
//
// 🚧 END Mock interface 🚧
//

/// Type-erasing closure wrapper for the property binding closure.
/// Calls the provided closure, and stores the result in the location indicated by the `pointer_to_value` pointer parameter.
fileprivate class SimpleBindingWrapper {
    private let _binding: (UnsafeMutableRawPointer) -> Void
    
    init<Ret>(_ binding: @escaping () -> Ret) {
        _binding = { valuePtr in
            let result = binding()
            // Store it at the location of `pointer_to_value`.
            valuePtr.assumingMemoryBound(to: Ret.self).initialize(to: result)
        }
    }
    
    func invoke(valuePtr: UnsafeMutableRawPointer) { _binding(valuePtr) }
}

/// Type-erasing closure wrapper for the property binding closure.
/// Only for state properties, which have a type `StateInfo` but return `Int32`.
fileprivate class StateBindingWrapper {
    private let _binding: () -> Int32
    init(_ binding: @escaping () -> Int32) { _binding = binding }
    func invoke() -> Int32 {  _binding() }
}

/// Wrapper that allows the two-way callbacks to access the shared property without
/// knowing its specialization.
fileprivate class TwoWayBindingWrapper {
    private let _binding:  (UnsafeMutableRawPointer) -> ()
    private let _intercept: (UnsafeRawPointer) -> ()
    private let _intercept_binding: (UnsafeMutableRawPointer) -> ()

    @MainActor
    init<T>(_ sharedProperty: Property<T>, _ unsafeHandle: UnsafePointer<PropertyWrapperOpaque>) {
        _binding = { valuePtr in
            valuePtr.assumingMemoryBound(to: T.self).initialize(to: sharedProperty.value)
        }

        _intercept = { valuePtr in
            sharedProperty.value = valuePtr.assumingMemoryBound(to: T.self).pointee
        }

        _intercept_binding = { bindingPtr in
            slint_property_set_binding_internal(
                unsafeHandle,
                bindingPtr
            )
        }
    }

    /// Invoke the wrapped `binding` closure.
    func invokeBinding(ptrToValue: UnsafeMutableRawPointer) {
        _binding(ptrToValue)
    }

    /// Invoke the wrapped `intercept_set` closure.
    func invokeInterceptSet(ptrToValue: UnsafeRawPointer) {
        _intercept(ptrToValue)
    }

    /// Invoke the wrapped `intercept_set_binding` closure.
    func invokeInterceptSetBinding(ptrToBinding: UnsafeMutableRawPointer) {
        _intercept_binding(ptrToBinding)
    }
}

/// A property stores either a value, or a binding to another property.
class Property<T> {
    // Opaque handle used by Slint to manage its representation of this property.
    private var handle: PropertyWrapperOpaque = PropertyWrapperOpaque()
    private var handleUnsafe: UnsafePointer<PropertyWrapperOpaque> {
        withUnsafePointer(to: handle) { $0 }
    }
    
    /// Initializer. Sets the initial value.
    @MainActor
    init(_ initialValue: T) {
        // Get a mutable pointer to handle.
        withUnsafeMutablePointer(to: &handle) { handlePtr in
            slint_property_init(handlePtr)
        }
        value = initialValue
    }

    /// Deinitializer. Tells Slint to clear out everything.
    deinit {
        slint_property_drop(handleUnsafe)
    }
    
    /// Computed property for `value` allows for using it directly.
    @MainActor
    var value: T {
        get {
            // Allocate space for the value
            let valuePtr = UnsafeMutableRawPointer.allocate(
                byteCount: MemoryLayout<T>.size,
                alignment: MemoryLayout<T>.alignment
            )
            defer { valuePtr.deallocate() }
            
            // Update the property to get its value
            slint_property_update(handleUnsafe, valuePtr)
            
            // Retrieve the value from the buffer
            let value = valuePtr.assumingMemoryBound(to: T.self).pointee
            return value
        }
        set {
            // Create an unsafe pointer to the new value
            withUnsafePointer(to: newValue) { valueUnsafe in
                // Create raw pointer
                let valuePtr = UnsafeRawPointer(valueUnsafe)
                
                // Tell Slint to update the property
                slint_property_set_changed(handleUnsafe, valuePtr)
            }
        }
    }
    
    /// Computed property for getting and setting `dirty`.
    @MainActor
    var dirty: CBool {
        get {
            return slint_property_is_dirty(handleUnsafe)
        }
        set {
            precondition(
                newValue == true,
                "Can't assign false to Property<T>.dirty!"
            )
            slint_property_mark_dirty(handleUnsafe)
        }
    }
    
    //
    // Type aliases
    //

    /// Type alias for the `binding` callback.
    typealias BindingCallback = @convention(c) (
        UnsafeMutableRawPointer, // user_data
        UnsafeMutableRawPointer  // pointer_to_value
    ) -> ()
    
    /// Type alias for the `drop_user_data` callback.
    typealias DropUserDataCallback = @convention(c) (
        UnsafeMutableRawPointer  // user_data
    ) -> ()

    /// Type alias for the `intercept_set` callback.
    typealias InterceptSetCallback = @convention(c) (
        UnsafeMutableRawPointer, // user_data
        UnsafeRawPointer         // pointer_to_value
    ) -> (CBool)
    
    /// Type alias for the `intercept_set_binding` callback.
    typealias InterceptSetBindingCallback = @convention(c) (
        UnsafeMutableRawPointer, // user_data
        UnsafeMutableRawPointer  // new_binding
    ) -> (CBool)

    /// Type alias for `binding` callbacks, for State bindings.
    typealias StateBindingCallback = @convention(c) (
        UnsafeMutableRawPointer  // user_data
    ) -> (Int32)

    //
    // Callbacks
    //

    /// Binding callback. Invokes the handler.
    private let bindingCallback: BindingCallback =
    { userDataPtr, ptrToValue in
        let wrapper = userDataPtr.assumingMemoryBound(
            to: SimpleBindingWrapper.self
        ).pointee
        wrapper.invoke(valuePtr: ptrToValue)
    }
    
    /// Drop user data callback. Releases the wrapper.
    private let dropUserDataCallback: DropUserDataCallback =
    { userDataPtr in
        // Convert the raw pointer to an unmanaged instance
        let wrapper = Unmanaged<SimpleBindingWrapper>.fromOpaque(userDataPtr)
        // Release the instance by taking the retained value
        _ = wrapper.takeRetainedValue()
    }

    /// Binding callback for two-way bindings. Accesses the shared property.
    private let twoWayBindingCallback: BindingCallback =
    { userDataPtr, ptrToValue in
        let wrapper = userDataPtr.assumingMemoryBound(
            to: TwoWayBindingWrapper.self
        ).pointee
        // Call the wrapped closure
        wrapper.invokeBinding(ptrToValue: ptrToValue)
    }

    /// Drop user data callback for two-way bindings. Releases the wrapper.
    private let twoWayDropUserDataCallback: DropUserDataCallback =
    { userDataPtr in
        // Convert the raw pointer to an unmanaged instance
        let wrapper = Unmanaged<TwoWayBindingWrapper>.fromOpaque(userDataPtr)
        // Release the instance by taking the retained value
        _ = wrapper.takeRetainedValue()
    }

    /// Intercept set callback. Only used for two-way bindings.
    private let interceptSetCallback: InterceptSetCallback =
    { userDataPtr, ptrToValue in
        let wrapper = userDataPtr.assumingMemoryBound(
            to: TwoWayBindingWrapper.self
        ).pointee
        // Call the wrapped closure
        wrapper.invokeInterceptSet(ptrToValue: ptrToValue)
        // Return true (meaning 'keep this binding')
        return true
    }

    /// Intercept set binding callback. Only used for two-way bindings.
    private let interceptSetBindingCallback: InterceptSetBindingCallback =
    { userDataPtr, bindingPtr in
        // Get the two-way wrapper
        let wrapper = userDataPtr.assumingMemoryBound(
            to: TwoWayBindingWrapper.self
        ).pointee
        // Call the wrapped closure
        wrapper.invokeInterceptSetBinding(ptrToBinding: bindingPtr)
        // Return true (meaning 'keep this binding')
        return true
    }

    /// Binding callback for state properties.
    private let stateBindingCallback: StateBindingCallback =
    { userDataPtr in
        let wrapper = userDataPtr.assumingMemoryBound(
            to: StateBindingWrapper.self
        ).pointee
        return wrapper.invoke()
    }

    /// Drop user data callback for state properties.
    private let stateDropUserDataCallback: DropUserDataCallback =
    { userDataPtr in
        // Convert the raw pointer to an unmanaged instance
        let wrapper = Unmanaged<StateBindingWrapper>.fromOpaque(userDataPtr)
        // Release the instance by taking the retained value
        _ = wrapper.takeRetainedValue()
    }

    /// Sets the binding to some closure that returns the correct value type.
    @MainActor
    func setBinding(_ binding: @escaping () -> T) {
        // Create a wrapper
        let newWrapper = SimpleBindingWrapper(binding)
        
        // Create an unmanaged reference, so it won't be destroyed immediately
        let wrapperRaw = Unmanaged.passRetained(newWrapper).toOpaque()
        
        // Create the binding
        slint_property_set_binding(
            handleUnsafe,
            bindingCallback,
            wrapperRaw,
            dropUserDataCallback,
            nil,
            nil
        )
    }

    /// Create a two-way binding
    @MainActor
    static func LinkTwoWay(_ P1: Property<T>, _ P2: Property<T>) {
        // Create a new property
        let sharedProperty = Property<T>(P2.value)

        // Swap the handle between the new property and P2, if a flag is set.
        // 🚩 This might be blatantly wrong!
        if (P2.handle._0 & 0b10) == 0b10 {
            // Can't use swap(_:_:) on two properties, I guess
            let temp = P2.handle
            P2.handle = sharedProperty.handle
            sharedProperty.handle = temp
        }

        // Create the two-way callback wrapper
        let wrapper = TwoWayBindingWrapper(sharedProperty, sharedProperty.handleUnsafe)

        // Take two retained pointers, for P1 and P2
        let retainedP1 = Unmanaged.passRetained(wrapper).toOpaque()
        let retainedP2 = Unmanaged.passRetained(wrapper).toOpaque()

        // Set the bindings for P1 and P2
        slint_property_set_binding(
            P1.handleUnsafe,
            P1.twoWayBindingCallback,
            retainedP1,
            P1.twoWayDropUserDataCallback,
            P1.interceptSetCallback,
            P1.interceptSetBindingCallback
        )
        slint_property_set_binding(
            P2.handleUnsafe,
            P2.twoWayBindingCallback,
            retainedP2,
            P2.twoWayDropUserDataCallback,
            P2.interceptSetCallback,
            P2.interceptSetBindingCallback
        )
    }
}

/****
*
* ANIMATION SUPPORT
*
****/

// Special handing for Int (C++: int32_t)
extension Property where T == Int32 {
    @MainActor
    func setAnimatedValue(_ newValue: T, animationData: PropertyAnimation) {
        withUnsafePointer(to: animationData) { unsafeAnimationData in
            slint_property_set_animated_value_int(
                handleUnsafe,
                value,
                newValue,
                unsafeAnimationData
            )
        }
    }

    /// Set binding with animation.
    /// `prop.setBinding(withAnimation: animation) { anotherProp.get }`
    @MainActor
    func setBinding(
        withAnimation animationData: PropertyAnimation,
        _ binding: @escaping () -> T
    ) {
        // Create a wrapper
        let wrapper = SimpleBindingWrapper(binding)
        
        // Create an unmanaged reference, so it won't be destroyed immediately
        let wrapperRaw = Unmanaged.passRetained(wrapper).toOpaque()
        
        // 🚨 Does Slint copy the value, or does it need to persist?
        withUnsafePointer(to: animationData) { animationPtr in
            slint_property_set_animated_binding_int(
                handleUnsafe,
                bindingCallback,
                wrapperRaw,
                dropUserDataCallback,
                animationPtr,
                nil
            )
        }
    }
}

// Special handling for Float (C++: float)
extension Property where T == CFloat {
    @MainActor
    func setAnimatedValue(_ newValue: T, animationData: PropertyAnimation) {
        withUnsafePointer(to: animationData) { animationDataPtr in
            slint_property_set_animated_value_float(
                handleUnsafe,
                value,
                newValue,
                animationDataPtr
            )
        }
    }

    /// Set binding with animation.
    /// `prop.setBinding(withAnimation: animation) { anotherProp.get }`
    @MainActor
    func setBinding(
        withAnimation animationData: PropertyAnimation,
        _ binding: @escaping () -> T
    ) {
        // Create a wrapper
        let wrapper = SimpleBindingWrapper(binding)
        
        // Create an unmanaged reference, so it won't be destroyed immediately
        let wrapperRaw = Unmanaged.passRetained(wrapper).toOpaque()
        
        // 🚨 Does Slint copy the value, or does it need to persist?
        withUnsafePointer(to: animationData) { animationPtr in
            slint_property_set_animated_binding_float(
                handleUnsafe,
                bindingCallback,
                wrapperRaw,
                dropUserDataCallback,
                animationPtr,
                nil
            )
        }
    }
}

extension Property where T == SlintColor {
    @MainActor
    func setAnimatedValue(_ newValue: T, animationData: PropertyAnimation) {
        withUnsafePointer(to: animationData) { unsafeAnimationData in
            slint_property_set_animated_value_color(
                handleUnsafe,
                value,
                newValue,
                unsafeAnimationData
            )
        }
    }

    /// Set binding with animation.
    /// `prop.setBinding(withAnimation: animation) { anotherProp.get }`
    @MainActor
    func setBinding(
        withAnimation animationData: PropertyAnimation,
        _ binding: @escaping () -> T
    ) {
        // Create a wrapper
        let wrapper = SimpleBindingWrapper(binding)
        
        // Create an unmanaged reference, so it won't be destroyed immediately
        let wrapperRaw = Unmanaged.passRetained(wrapper).toOpaque()
        
        // 🚨 Does Slint copy the value, or does it need to persist?
        withUnsafePointer(to: animationData) { animationPtr in
            slint_property_set_animated_binding_color(
                handleUnsafe,
                bindingCallback,
                wrapperRaw,
                dropUserDataCallback,
                animationPtr,
                nil
            )
        }
    }
}

extension Property where T == SlintBrush {
    /// Set binding with animation.
    /// `prop.setBinding(withAnimation: animation) { anotherProp.get }`
    @MainActor
    func setBinding(
        withAnimation animationData: PropertyAnimation,
        _ binding: @escaping () -> T
    ) {
        // Create a wrapper
        let wrapper = SimpleBindingWrapper(binding)
        
        // Create an unmanaged reference, so it won't be destroyed immediately
        let wrapperRaw = Unmanaged.passRetained(wrapper).toOpaque()
        
        // 🚨 Does Slint copy the value, or does it need to persist?
        withUnsafePointer(to: animationData) { animationPtr in
            slint_property_set_animated_binding_brush(
                handleUnsafe,
                bindingCallback,
                wrapperRaw,
                dropUserDataCallback,
                animationPtr,
                nil
            )
        }
    }
}

/****
*
* STATE BINDING SUPPORT
*
****/
extension Property where T == StateInfo {
    /// Set binding, specialized for StateInfo properties.
    /// The difference is the `binding` closure: it returns an Int32.
    @MainActor
    func setBinding(
        _ binding: @escaping () -> Int32
    ) {
        // Create a wrapper
        let wrapper = SimpleBindingWrapper(binding)
        
        // Create an unmanaged reference, so it won't be destroyed immediately
        let wrapperRaw = Unmanaged.passRetained(wrapper).toOpaque()

        slint_property_set_state_binding(
            handleUnsafe,
            stateBindingCallback,
            wrapperRaw,
            stateDropUserDataCallback
        )
    }
}
