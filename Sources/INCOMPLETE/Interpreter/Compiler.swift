//
//  Compiler.swift
//  slint
//
//  Created by Matthew Taylor on 2/17/24.
//

// For URL
import Foundation

import SlintFFI

/// A compiler interprets Slint code and creates component definitions, which can be used to instantiate components.

// Do we need actor isolation for this type?
@SlintActor
public class SlintCompiler {
    /// Pointer to the compiler we're wrapping around.
    private var handle: OpaquePointer?

    /// Unsafe pointer to the handle
    private var handleUnsafe: UnsafePointer<OpaquePointer?> { withUnsafePointer(to: handle) { $0 } }

    /// Mutable unsafe pointer to the handle
    private var handleUnsafeMut: UnsafeMutablePointer<OpaquePointer?> { withUnsafeMutablePointer(to: &handle) { $0 } }

    /// Enum to describe error conditions.
    enum CompilerError: Error {
        case constructorFailed
        case invalidPath
        case compileFailed
    }

    /// Initializer. Constructs a default compiler instance.
    /// Throws `CompilerError.constructorFailed` on error.
    public init() throws {
        // Slint wants us to pass it a reference to the 
        withUnsafeMutablePointer(to: &handle) { handleOpaque in
            slint_interpreter_component_compiler_new(handleOpaque)
        }
        if handle == nil {
            throw CompilerError.constructorFailed
        }
    }

    /// Deinitializer. Destructs the wrapped compiler instance.
    deinit {
        // This should never be false, but just in case?
        // Have to use a guard, because it complains that the assert autoclosure isn't isolated.
        guard handle != nil else {
            assert(false, "SlintCompiler was initialized with handle == nil?")
        }
        withUnsafeMutablePointer(to: &handle) { handleOpaque in
            slint_interpreter_component_compiler_destructor(handleOpaque)
        }
    }

    /// Compile the source code provided as a string into a component definition.
    /// Note: throws `CompilerError.compileFailed` if the compiler failed.
    public func build(fromSource source: () -> String) throws -> ComponentDefinition {

        // Get that text
        let srcText = source()

        // Pretend we did something with the path parameter
        let pathText = ""

        // Create a new component definition for the function to vomit into.
        let component = ComponentDefinition()

        // Store if we suceeded or not.
        var successful = false

        // EWW
        pathText.withStrSlice { pathSlice in
            // EWWWW
            srcText.withStrSlice { srcSlice in
                successful = slint_interpreter_component_compiler_build_from_source(
                    self.handleUnsafeMut,
                    srcSlice,
                    pathSlice,
                    component.getHandleUnsafeMut()
                )
            }
        }

        // Did it work?
        guard successful else { throw CompilerError.compileFailed }

        // I'm so fucking done.
        return component
    }
}

// Convert string to string slice, for Slint APIs.
extension String {
    /// Calls the given closure with a pointer to the contents of the string, represented as a Slint `Slice<uint8_t>`.
    /// - Parameter closure: The closure to run.
    func withStrSlice(_ closure: (StrSlice) -> Void) {
        self.withCString { strPtr in
            var slice = StrSlice()
        
            // Strip the null byte? Some Slint APIs expect no null termination.
            slice.len = UInt(self.utf8CString.count - 1)

            // Swift C string is UnsafeBufferPointer<Int8>, we need UnsafeMutablePointer<UInt8>
            // 🤢
            let unsafePtr = UnsafeRawPointer(strPtr)
            slice.ptr = unsafePtr.assumingMemoryBound(to: UnsafeMutablePointer<UInt8>.self).pointee

            closure(slice)
        }
    }
}