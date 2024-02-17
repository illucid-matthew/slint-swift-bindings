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
@MainActor
public class SlintCompiler {
    /// Pointer to the compiler we're wrapping around.
    private var handle: OpaquePointer?

    /// Enum to describe error conditions.
    enum CompilerError: Error {
        case constructorFailed
        case invalidPath
        case compileFailed
    }

    /// Initializer. Constructs a default compiler instance.
    /// Throws `CompilerError.constructorFailed` on error.
    init() throws {
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
    /// - Parameters:
    ///   - source: The Slint source code to compile.
    ///   - path: A base path to use for any imports.
    /// - Returns: A component definition instance.
    /// 
    /// Note: throws `CompilerError.compileFailed` if the compiler failed.
    func build(fromSource source: String, atPath path: URL?) throws -> ComponentDefinition {
        // Throw if the URL is not a file path
        guard (path == nil) || (path?.isFileURL == true) else {
            throw CompilerError.invalidPath
        }

        throw CompilerError.compileFailed
    }
}