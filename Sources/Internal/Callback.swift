//
// Callback.swift
// slint
//
// Created by Matthew Taylor on 2/6/24.
//

//
// 🚧 Mock interface 🚧
//
struct CallbackOpaque { }

func slint_callback_init(_ out: UnsafeMutablePointer<CallbackOpaque>) { }
func slint_callback_call(
    _ sig: UnsafePointer<CallbackOpaque>,
    _ arg: UnsafeRawPointer,
    _ ret: UnsafeMutableRawPointer
) { }
func slint_callback_set_handler(
    _ sig: UnsafePointer<CallbackOpaque>,
    _ binding: @convention(c) (UnsafeMutableRawPointer, UnsafeRawPointer, UnsafeMutableRawPointer) -> Void,
    _ userData: UnsafeMutableRawPointer,
    _ dropUserData: (UnsafeMutableRawPointer) -> Void
) { }
func slint_callback_drop(_ handle: UnsafeMutablePointer<CallbackOpaque>) { }
//
// 🚧 END Mock interface 🚧
//

/// Type-erasing closure wrapper. Allows the closure to be invoked from closures using C calling conventions, which _cannot_ capture generic parameters.
/// Instead, the generic parameter are captured in a Swift closure, which can then be invoked from C convention closures through the `user_data` pointer.
fileprivate class ClosureWrapper {
    // Wrapped closure. Uses Swift calling conventions, and captures `Arg` and `Ret` generic parameters from the initializer.
    private let _invoke: (UnsafeRawPointer, UnsafeMutableRawPointer) -> Void
    
    /// Initializer. Uses generics specialization to guarantee type safety.
    init<Arg, Ret>(_ closure: @escaping (Arg) -> Ret) {
        _invoke = { argRaw, retRaw in
            let arg = argRaw.assumingMemoryBound(to: Arg.self).pointee
            let result: Ret = closure(arg)
            retRaw.assumingMemoryBound(to: Ret.self).initialize(to: result)
        }
    }
    
    /// Invoke the closure.
    /// Technically we don't need this. But its nicer than exposing the closure.
    func invoke(arg: UnsafeRawPointer, ret: UnsafeMutableRawPointer) {
        _invoke(arg, ret)
    }
}

/// A `Callback` is a object that invokes a closure when called.
/// These are used to allow for dynamic behavior of components.
/// Callbacks are executed on the main actor as part of Slint's event loop.
@MainActor
class Callback<Arg, Ret> {
    // Opaque handle used by Slint to manage its representation of this callback.
    private var handle: CallbackOpaque = CallbackOpaque()
    private var handleUnsafe: UnsafePointer<CallbackOpaque> {
        withUnsafePointer(to: handle) { $0 }
    }
    
    /// Initializer. Create the callback in Slint.
    init() {
        withUnsafeMutablePointer(to: &handle) { handleMut in
            slint_callback_init(handleMut)
        }
    }

    /// Deinitializer. Tells Slint to clear out everything.
    deinit {
        withUnsafeMutablePointer(to: &handle) { handleMut in
            slint_callback_drop(handleMut)
        }
    }
    
    /// Set a new handler for a callback.
    func setHandler(_ closure: @escaping (Arg) -> Ret) {
        // Create a new wrapper
        let wrapper = ClosureWrapper(closure)
        
        // Create an unmanaged reference, so we can pass it to the FFI without ARC assuming its unowned and destroying it.
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()
        
        slint_callback_set_handler(
            handleUnsafe,
            bindingCallback,
            wrapperPtr,
            dropUserDataCallback
        )
    }
    
    /// Invoke the callback.
    func call(arg: Arg) throws -> Ret {
        // Allocate space for the return value
        let returnPtr = UnsafeMutableRawPointer.allocate(
            byteCount: MemoryLayout<Ret>.size,
            alignment: MemoryLayout<Ret>.alignment
        )
        // This will always deallocate, regardless of how the method exits
        defer { returnPtr.deallocate() }
        
        // Create an unsafe pointer to the arg
        withUnsafePointer(to: arg) { argUnsafe in
            // Create a raw pointer
            let argPtr = UnsafeRawPointer(argUnsafe)
            // Invoke the callback handler
            slint_callback_call(handleUnsafe, argPtr, returnPtr)
        }
        
        // Return that value. The `defer` block will handle the dealloaction.
        return returnPtr.assumingMemoryBound(to: Ret.self).pointee
    }
    
    /// Type alias for the `binding` callback.
    typealias BindingCallback = @convention(c) (
        UnsafeMutableRawPointer, // user_data
        UnsafeRawPointer, // arg
        UnsafeMutableRawPointer // ret
    ) -> ()
    
    /// Type alias for the `drop_user_data` callback.
    typealias DropUserDataCallback = @convention(c) (
        UnsafeMutableRawPointer // user_data
    ) -> ()
    
    /// Binding callback. Invokes the handler.
    private let bindingCallback: BindingCallback =
    { userDataPtr, argPtr, returnPtr in
        // Convert the raw pointer to an instance reference
        let wrapper = userDataPtr.assumingMemoryBound(to: ClosureWrapper.self).pointee
        // Invoke the closure
        wrapper.invoke(arg: argPtr, ret: returnPtr)
    }
    
    /// Drop user data callback. Releases the wrapper.
    private let dropUserDataCallback: DropUserDataCallback =
    { userDataPtr in
        // Convert the raw pointer to an unmanaged instance
        _ = Unmanaged<ClosureWrapper>.fromOpaque(userDataPtr).takeRetainedValue()
    }
}
