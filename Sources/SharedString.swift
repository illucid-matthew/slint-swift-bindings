//
//  SharedString.swift
//  Slint
//
//  Created by Matthew Taylor on 2/8/24.
//

//
// 🚧 Mock interface 🚧
//
func slint_shared_string_bytes(_ str: UnsafePointer<OpaquePointer>) -> UnsafeBufferPointer<CChar> { return UnsafeBufferPointer(start: nil, count: 0) }
func slint_shared_string_drop(_ str: UnsafePointer<OpaquePointer>) { }
func slint_shared_string_from_bytes(_ out: UnsafePointer<OpaquePointer>, _ bytes: UnsafePointer<CChar>, _ len: UInt) { }
//
// 🚧 END mock interface 🚧
//

/// String managed by the Slint runtime. Not implemented as copy-on-write, because that's balls.
/// This class is a lazy adaption. To make changes, operate on `value`.
@MainActor
class SharedString {
    private var handle: OpaquePointer
    private var unsafeHandle: UnsafePointer<OpaquePointer> {
        UnsafePointer<OpaquePointer>.init(handle)
    }
    
    /// Access the underlying string, as a Swift string.
    var value: String {
        get {
            // Create a Swift string by copying the existing string.
            let value = slint_shared_string_bytes(unsafeHandle)
            return String(cString: value.baseAddress!)
        }
        set {
            // Drop the existing string
            // HACK: Check for initial value
            if handle != OpaquePointer.init(bitPattern: -1)! {
                slint_shared_string_drop(unsafeHandle)
            }
            
            // Create a new string. Slint expects UTF-8, with no null byte. Swift adds a null byte.
            let length = newValue.utf8CString.count - 1
            
            // Call Slint to copy the bytes.
            newValue.withCString { newStringPtr in
                slint_shared_string_from_bytes(unsafeHandle, newStringPtr, UInt(length))
            }
        }
    }
    
    /// Initializer.
    init(_ initialValue: String = "") {
        // Set handle, so we can pass it to Slint without Swift complaining about uninitialized properties.
        handle = OpaquePointer.init(bitPattern: -1)!
        // Copy the initial value in.
        value = initialValue
    }
    
    /// Deinitializer. Frees the string.
    deinit {
        // To work around non-isolated deinit rules, which prevent side effects in deinit.
        // Get the value directly, without the computed property.
        let ptrToDrop = UnsafePointer<OpaquePointer>.init(handle)
        // Drop it.
        slint_shared_string_drop(ptrToDrop)
    }
}
