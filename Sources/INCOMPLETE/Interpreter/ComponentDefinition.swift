//
//  ComponentDefinition.swift
//  slint
//
//  Created by Matthew Taylor on 2/17/24.
//

import SlintFFI

// Same as Compiler, is isolation necessary for this type?
@SlintActor
public class ComponentDefinition {
    /// Pointer to the component definition we're wrapping around.
    private var handle: ComponentDefinitionOpaque = ComponentDefinitionOpaque()

    /// Bullshit so SlintCompiler can initialize us
    public func getHandleUnsafeMut() -> UnsafeMutablePointer<ComponentDefinitionOpaque> {
        withUnsafeMutablePointer(to: &handle) { $0 } 
    }

    /// Deinitializer. Destroys this component definition. Side effects unknown.
    deinit {
        withUnsafeMutablePointer(to: &handle) { handleOpaque in
            slint_interpreter_component_definition_destructor(handleOpaque)
        }
    }
}