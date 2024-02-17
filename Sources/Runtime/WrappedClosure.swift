//
//  WrappedClosure.swift
//  slint
//
//  Created by Matthew Taylor on 2/14/24.
//

// NOTE: Only for Thread.current.isMainThread
import Foundation

/// Wrapper around a Swift closure, allowing it to be invoked by Slint.
/// There are different version specialized for specific APIs.
/// This one is meant for the most common use case.
/// 
/// Note: this is only meant for Slint APIs which expected you to pass a function pointer to them.
/// If you just need to run something in the Slint event loop, use `EventLoop.run(_:)` or `@SlintActor`.
class WrappedClosure {
    /// Wrapped closure value. Runs with `SlintActor` isolation.
    private let invoke: @SlintActor () -> Void
    /// Reference to thing. Used to allow timers to hold a reference without dying.
    private var ref: AnyObject? = nil

    /// Initializer. Stores the closure.
    /// - Parameter closure: The Swift closure to wrap.
    /// 
    /// If you need to save the value, use `withResult(_:)` or `withResultThrowing(_:)`.
    init(_ closure: @SlintActor @escaping @Sendable () -> Void) {
        invoke = {
            assert(Thread.current.isMainThread, "Closure not running on main thread!")
            closure()
        }
    }

    /// Stupid way to ensure that an object doesn't disappear.
    public func holdOntoThis(_ thing: AnyObject) {
        ref = thing
    }
   
    /// Factory function. Creates a wrapped closure that captures a value.
    /// - Parameter closure: A closure that returns a value.
    /// - Returns:  A tuple of a wrapper instance, and a channel to recieve the value.
    static func withResult<Ret>(
        _ closure: @SlintActor @escaping @Sendable () -> Ret
    ) -> (WrappedClosure, AsyncChannel<Ret>) {

        // Channel for returning a value.
        let channel = AsyncChannel(Ret.self)

        // Create wrapper with a closure that sends the result through the channel.
        let wrapper = WrappedClosure {
            assert(Thread.current.isMainThread, "Closure not running on main thread!")
            channel.send(closure())
        }
        
        // Return both.
        return (wrapper, channel)
    }
  
    /// Factory function. Creates a wrapped closure that captures a value and may throw.
    /// - Parameter closure: A closure that returns a value and may throw.
    /// - Returns: A tuple of a wrapper instance, and a channel to recieve a result.
    static func withResultThrowing<Ret>(
        _ closure: @SlintActor @escaping @Sendable () throws -> Ret
    ) -> (WrappedClosure, AsyncChannel<Result<Ret, Error>>) {

        // Channel for returning a value.
        let channel = AsyncChannel(Result<Ret, Error>.self)

        // Create wrapper with a closure that sends the result through the channel using `Result`.
        let wrapper = WrappedClosure {
            assert(Thread.current.isMainThread, "Closure not running on main thread!")
            channel.send( Result { try closure() } )
        }
        
        // Return both.
        return (wrapper, channel)
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
        let pointer = Unmanaged<WrappedClosure>.passRetained(self).toOpaque()
        return pointer
    }

    /// Type alias for the `invoke` callback.
    public typealias GenericInvokeCallback = (@convention(c) (UnsafeMutableRawPointer?) -> Void)?
    
    /// Type alias for the `drop_user_data` callback.
    public typealias DropUserDataCallback = (@convention(c) (UnsafeMutableRawPointer?) -> Void)?

    /// Closure that invokes a callback.
    public static let invokeCallback: GenericInvokeCallback = { userDataPtr in

        // Get a reference to this instance from an opaque pointer.
        let wrapper = Unmanaged<WrappedClosure>.fromOpaque(userDataPtr!).takeUnretainedValue()

        // This is nasty and quite gross, but necessary.
        // We _are_ in the SlintActor isolation context, but Swift does not let us tell it so!
        // See here: https://github.com/apple/swift-evolution/blob/main/proposals/0392-custom-actor-executors.md#assuming-actor-executors
        
        // Inspired by: https://forums.swift.org/t/se-0392-custom-actor-executors/63599/26
        // Basically, make Swift ignore the `@SlintActor` isolation by FORCING a type cast.

        // Sometimes, you just need a sledgehammer 🔨
        unsafeBitCast(wrapper.invoke, to: (() -> Void).self)()
    }

    /// Drop user data callback. Releases the wrapper.
    public static let dropCallback: DropUserDataCallback = { userDataPtr in
        
        // Get a reference to this instance from an opaque pointer, and release it.
        Unmanaged<WrappedClosure>.fromOpaque(userDataPtr!).release()
    }
}
