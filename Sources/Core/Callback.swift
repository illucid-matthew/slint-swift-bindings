//
// Callback.swift
// slint
//
// Created by Matthew Taylor on 2/6/24.
//

import Foundation

import SlintFFI

/// CURRENT STATUS: ☠️ DOES NOT WORK ☠️
/// 
/// Causes a bus error, with a backtrace:
/// 
/// * thread #1, queue = 'com.apple.main-thread', stop reason = EXC_BAD_ACCESS (code=257, address=0x910003fda9bf7bfd)
///   * frame #0: 0x000003fda9bf7bfd
///     frame #1: 0x000000010321ac40 libslint_cpp.dylib`core::ptr::drop_in_place$LT$alloc..boxed..Box$LT$dyn$u20$core..ops..function..FnMut$LT$$LP$$RF$$LP$$RP$$C$$RF$mut$u20$$LP$$RP$$RP$$GT$$u2b$Output$u20$$u3d$$u20$$LP$$RP$$GT$$GT$::h389bad9f3a99fcf6((null)=0x000000016fdfef98) at mod.rs:498:1
///     frame #2: 0x000000010321b044 libslint_cpp.dylib`core::ptr::drop_in_place$LT$core..option..Option$LT$alloc..boxed..Box$LT$dyn$u20$core..ops..function..FnMut$LT$$LP$$RF$$LP$$RP$$C$$RF$mut$u20$$LP$$RP$$RP$$GT$$u2b$Output$u20$$u3d$$u20$$LP$$RP$$GT$$GT$$GT$::h2e784ca1072556b7((null)=0x000000016fdfef98) at mod.rs:498:1
///     frame #3: 0x00000001031f8b60 libslint_cpp.dylib`core::cell::Cell$LT$T$GT$::set::h5f990a57f826cbf2 at mod.rs:992:24
///     frame #4: 0x00000001031f8b5c libslint_cpp.dylib`core::cell::Cell$LT$T$GT$::set::h5f990a57f826cbf2(self=0x000000016fdff028, val=Option<alloc::boxed::Box<dyn core::ops::function::FnMut<(&(), &mut ()), Output=()>, alloc::alloc::Global>> @ 0x000000016fdfefb0) at cell.rs:413:9
///     frame #5: 0x00000001031eb79c libslint_cpp.dylib`slint_callback_set_handler(sig=0x000000016fdff028, binding=(libSlintUI.dylib`@objc closure #1 (Swift.Optional<Swift.UnsafeMutableRawPointer>, Swift.Optional<Swift.UnsafeRawPointer>, Swift.Optional<Swift.UnsafeMutableRawPointer>) -> () in variable initialization expression of static SlintUI.WrappedCallback.bindingCallback : Swift.Optional<@convention(c) (Swift.Optional<Swift.UnsafeMutableRawPointer>, Swift.Optional<Swift.UnsafeRawPointer>, Swift.Optional<Swift.UnsafeMutableRawPointer>) -> ()> at <compiler-generated>), user_data=0x0000600002f10e00, drop_user_data=Option<extern "C" fn(*mut ())> @ 0x000000016fdff050) at callbacks.rs:149:9
///     frame #6: 0x00000001004a48b8 libSlintUI.dylib`slint_callback_set_handler(sig=0x000000016fdff028, binding=(libSlintUI.dylib`@objc closure #1 (Swift.Optional<Swift.UnsafeMutableRawPointer>, Swift.Optional<Swift.UnsafeRawPointer>, Swift.Optional<Swift.UnsafeMutableRawPointer>) -> () in variable initialization expression of static SlintUI.WrappedCallback.bindingCallback : Swift.Optional<@convention(c) (Swift.Optional<Swift.UnsafeMutableRawPointer>, Swift.Optional<Swift.UnsafeRawPointer>, Swift.Optional<Swift.UnsafeMutableRawPointer>) -> ()> at <compiler-generated>), user_data=0x0000600002f10e00, drop_user_data=(libSlintUI.dylib`@objc closure #1 (Swift.Optional<Swift.UnsafeMutableRawPointer>) -> () in variable initialization expression of static SlintUI.WrappedCallback.dropCallback : Swift.Optional<@convention(c) (Swift.Optional<Swift.UnsafeMutableRawPointer>) -> ()> at <compiler-generated>)) at FFI.h:743:12
///     frame #7: 0x00000001004a4674 libSlintUI.dylib`SlintCallback.setHandler(closure=0x100002ce8, self=0x0000600002f10da0) at Callback.swift:133:9
/// 
/// Looking at the backtrace and disassembly of frame #1, core::ptr::drop_in_place (from Rust) is branching to a SUPER high memory address.
/// On my machine, it's consistently at 0x000003fda9bf7bfd, even across sessions. IDK.
/// 
/// From here: https://opentitan.org/book/doc/rust_for_c_devs.html
/// > std::ptr::drop_in_place()83 can be used to run the destructor in the value behind a raw pointer, without technically giving up access to it.
/// 
/// That would suggest its trying to run a destructor, but getting a crazy value and exploding.
/// I don't know enough about Rust memory management to say what's really going on.
/// And I'm not interested in becoming an expert to decode it.
/// q

/// Private class for wrapped closure. Based on `WrappedClosure`, but modified for callbacks,
/// which are expected to take arguments and return values.
fileprivate class WrappedCallback {
    private var invoke: @SlintActor (UnsafeRawPointer, UnsafeMutableRawPointer) -> Void

    /// Initializer. Type parameters `Arg` and `Ret` are stored in the `invoke` closure.
    init<Arg, Ret>(_ closure: @SlintActor @escaping @Sendable (Arg) -> Ret) {
        invoke = { argPtr, retPtr in
            assert(Thread.current.isMainThread, "Callback not running on main thread!")
            let arg = argPtr.assumingMemoryBound(to: Arg.self).pointee
            retPtr.assumingMemoryBound(to: Ret.self).initialize(to: closure(arg))
        }
    }

    /// Convience method to do an unbalanced retain and get an opaque pointer to this instance.
    /// - Returns: An opaque pointer to this instance.
    /// 
    /// Note: This is meant for Slint APIs, to be passed as `user_data`.
    /// The `drop_user_data` callback you provide MUST use `Unmanaged` to release this instance.
    /// 
    /// See `WrappedClosure.dropCallback` as an example.
    @inlinable
    public func getRetainedPointer() -> UnsafeMutableRawPointer {
        let pointer = Unmanaged<WrappedCallback>.passRetained(self).toOpaque()
        return pointer
    }

    /// Type alias for the `binding` callback.
    typealias BindingCallback = (@convention(c) (UnsafeMutableRawPointer?, UnsafeRawPointer?, UnsafeMutableRawPointer?) -> Void)?
    
    /// Type alias for the `drop_user_data` callback.
    typealias DropUserDataCallback = (@convention(c) (UnsafeMutableRawPointer?) -> Void)?

    /// Binding callback. Invokes the handler.
    public static let bindingCallback: BindingCallback = { userDataPtr, argPtr, retPtr in
        // Convert the raw pointer to an instance reference
        let wrapper = Unmanaged<WrappedCallback>.fromOpaque(userDataPtr!).takeUnretainedValue()

        // Same as `WrappedClosure.invokeCallback`, bit cast to remove isolation requirement.
        // Because it is isolated, Swift just doesn't let us prove it.
        unsafeBitCast(
            wrapper.invoke,
            to: ((UnsafeRawPointer, UnsafeMutableRawPointer) -> Void).self
        )(argPtr!, retPtr!)
    }
    
    /// Drop user data callback. Releases the wrapper.
    public static let dropCallback: DropUserDataCallback = { userDataPtr in
        // Convert the raw pointer to an unmanaged instance
        Unmanaged<WrappedCallback>.fromOpaque(userDataPtr!).release()
    }
}

/// Calls a closure when invoked. Can take arguments, and return a result.
@SlintActor
public class SlintCallback<Arg, Ret> {
    /// Handle for the callback this instance controls.
    private var handle: CallbackOpaque = CallbackOpaque()
    /// Convience. Get an unsafe pointer to the handle.
    private var handleUnsafe: UnsafePointer<CallbackOpaque> {
        withUnsafePointer(to: handle) { $0 }
    }

    /// Initializer. Creates a callback.
    public init(_ argType: Arg.Type = Arg.self, _ retType: Ret.Type = Ret.self) {
        debugPrint(handle)
        withUnsafeMutablePointer(to: &handle) { handleOpaque in
            slint_callback_init(handleOpaque)
        }
        debugPrint(handle)
    }

    /// Convience initializer. Creates a callback and sets the handler.
    /// - Parameter closure: The closure to invoke when the callback is invoked.
    public convenience init(_ closure: @SlintActor @escaping @Sendable (Arg) -> Ret) {
        // Call the designated initializer
        self.init(Arg.self, Ret.self)

        // Set the handler
        setHandler(closure)
    }

    /// Deinitializer. Drops a callback.
    deinit {
        withUnsafeMutablePointer(to: &handle) { handleOpaque in
            slint_callback_drop(handleOpaque)
        }
    }

    /// Set the handler for this callback.
    /// - Parameter closure: The closure to invoke when the callback is invoked.
    public func setHandler(_ closure: @SlintActor @escaping @Sendable (Arg) -> Ret) {
        // Create a wrapper.
        // Like Timer, we must prevent Swift from dropping this unless Slint drops `user_data`.
        // Once Slint does, the closure will be released, and thus this Callback instance.
        let wrapper = WrappedCallback { arg in
            withExtendedLifetime(self) { return closure(arg) }
        }

        slint_callback_set_handler(
            handleUnsafe,
            WrappedCallback.bindingCallback,
            wrapper.getRetainedPointer(),
            WrappedCallback.dropCallback
        )
    }

    /// Invoke the callback with the given arguments.
    /// - Parameter arg: The arguments to pass to the callback.
    /// - Returns: The return value of the closure.
    public func invoke(_ arg: Arg) -> Ret {
        // Allocate space for the return value
        let retUnsafe = UnsafeMutableRawPointer.allocate(
            byteCount: MemoryLayout<Ret>.size,
            alignment: MemoryLayout<Ret>.alignment
        )
        // Release it when the function exits, so it doesn't leak.
        defer { retUnsafe.deallocate() }

        withUnsafePointer(to: arg) { argUnsafe in
            // Invoke the handler
            slint_callback_call(handleUnsafe, argUnsafe, retUnsafe)
        }

        // Return the value.
        return retUnsafe.assumingMemoryBound(to: Ret.self).pointee
    }
}

// Extension. Removes allocating space for the return pointer, if the callback doesn't return anything.
public extension SlintCallback where Ret == Void {
    /// Invoke the callback with the given arguments.
    /// - Parameter arg: The arguments to pass to the callback.
    func invoke(_ arg: Arg) -> Void {
        // Invoke the handler
        withUnsafePointer(to: arg) { argUnsafe in
            slint_callback_call(handleUnsafe, argUnsafe, nil)
        }
    }
}

public extension SlintCallback where Arg == Void {
    /// Invoke the callback with no arguments.
    /// - Returns: The return value of the closure.
    func invoke() -> Ret {
        // Allocate space for the return value
        let retUnsafe = UnsafeMutableRawPointer.allocate(
            byteCount: MemoryLayout<Ret>.size,
            alignment: MemoryLayout<Ret>.alignment
        )
        // Release it when the function exits, so it doesn't leak.
        defer { retUnsafe.deallocate() }

        // Invoke the handler
        slint_callback_call(handleUnsafe, nil, retUnsafe)

        // Return the value.
        return retUnsafe.assumingMemoryBound(to: Ret.self).pointee
    }
}

public extension SlintCallback where Arg == Void, Ret == Void {
    /// Invoke the callback with no arguments.
    func invoke() -> Void {
        slint_callback_call(handleUnsafe, nil, nil)
    }
}