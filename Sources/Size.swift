//
//  Size.swift
//  Slint
//
//  Created by Matthew Taylor on 2/8/24.
//

// Bridges to the `Size2D` type from the Euclid crate, if the C++ binding comments are to be believed.

/// A physical two-dimensional size, with width and height.
struct Size<T: Equatable>: Equatable {
    var width, height: T
}

/// A size, given in logical pixels.
typealias LogicalSize = Size<CFloat>

/// A size, given in physical pixels.
typealias PhysicalSize = Size<UInt32>
