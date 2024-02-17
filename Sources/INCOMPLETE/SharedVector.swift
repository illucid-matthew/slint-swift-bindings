//
// SharedVector.swift
// slint
//
// Created by Matthew Taylor on 2/6/24.
//

// We don't have std::atomic, but this is essentially the same thing, right?
import Atomic

//
// 🚧 Mock interface 🚧
//
func slint_shared_vector_empty() -> UnsafePointer<UInt8> { UnsafeRawPointer(bitPattern: -1)!.assumingMemoryBound(to: UInt8.self) }
func slint_shared_vector_allocate(_ size: UInt, _ align: UInt) -> UnsafeMutablePointer<UInt8> { UnsafeMutableRawPointer(bitPattern: -1)!.assumingMemoryBound(to: UInt8.self) }
func slint_shared_vector_free(_ ptr: UnsafeMutablePointer<UInt8>, _ size: UInt, _ align: UInt) { }
//
// 🚧 END Mock interface 🚧
//

/// Header for a shared vector. Values of this type are allocated on the heap and managed by Slint.
fileprivate struct SharedVectorHeader {
    /// Number of current references to this vector.
    @Atomic var refCount: Int   = 1
    /// Number of used elements.
    var size: Int               = 0
    /// Number of elements allocated.
    var capacity: Int           = 0
    
    /// Cannot be created directly. Do not try.
    private init() {
        assert(false, "SharedVectorHeader is not meant to be created directly!")
        refCount = Int.min; size = Int.min; capacity = Int.min
    }
}

/// Shared vector, where the memory is managed by Slint.
/// 
/// Meant for efficient sharing between the Slint runtime and an application, without large volumes of copying.
///
/// Much to the chagrin of the the author 💀.
///
/// That said, Swift provides `UnsafeMutableBufferPointer` for just this kind of occassion.
/// So I won't have to do all that pointer arithmatic BS.
///
/// Also, most of the C++ binding reference count shenanigans don't apply, because `SharedVector<T>` is already a reference type.
/// Swift provides automatic reference counting. To the Slint runtime, it's all the same reference, no matter how many times you copy a `SharedVector` instance.
class SharedVector<T>: MutableCollection {
    //
    // Public interface stuff
    //

    /// First element index.
    private(set) var startIndex: Int = 0
    
    /// Index one past the last element.
    private(set) var endIndex: Int = 1
    
    /// Index immediately after.
    func index(after i: Int) -> Int { i + 1 }
    
    /// Return the value at a given index.
    @MainActor
    subscript(position: Int) -> T {
        get {
            precondition(position >= 0, "Index cannot be negative!")
            precondition(position < buffer.count, "Index out of bounds!")
            
            return buffer[position]
        }
        set {
            precondition(position >= 0, "Index cannot be negative!")
            precondition(position < buffer.count, "Index out of bounds!")
            
            // If the values are equal, do nothing
            if Self.areEqual(newValue, buffer[position]) { return }
            
            // Copy-on-write?
            aboutToWrite()
            
            buffer[position] = newValue
        }
    }
    
    /// Append an item to the end of the list.
    @MainActor
    func append(_ item: T) {
        // Add more capacity.
        aboutToWrite(newCapacity: header.capacity + 1)
        
        // Set final value
        self[endIndex] = item
        
        // Increment size
        header.size += 1
    }
    
    /// Default initializer. `required` because Swift says it needs to be for `aboutToWrite` to use it.
    @MainActor
    required init() {
        // Nasty, but without it Swift complains about uninitialized stored properties.
        // It gets immediately overwritten by headerPtr's property observer.
        buffer = UnsafeMutableBufferPointer<T>(start: UnsafeMutableRawPointer.init(bitPattern: -1)?.assumingMemoryBound(to: T.self), count: -1)
        
        headerPtr = Self.getEmptyVector()
    }
    
    /// Initializer with default values provided.
    @MainActor
    init(_ initialValues: T...) {
        // Nasty, but without it Swift complains about uninitialized stored properties.
        // It gets immediately overwritten by headerPtr's property observer.
        buffer = UnsafeMutableBufferPointer<T>(start: UnsafeMutableRawPointer.init(bitPattern: -1)?.assumingMemoryBound(to: T.self), count: -1)
        
        // Create a new vector with enough space for the arguments
        headerPtr = Self.newVector(capacity: initialValues.count)
        
        // Assign values
        copyFromCollection(initialValues)
    }
    
    //
    // Private stuff
    //
    
    /// Header pointer. Slint runtime allocates this value on the heap, so we can only store a pointer to it.
    private var headerPtr: UnsafeMutablePointer<SharedVectorHeader> {
        didSet {
            // Get pointer to memory immedately following the header, and assume it's a pointer to a `T` value.
            let rawPtr = UnsafeMutableRawPointer(headerPtr + 1).assumingMemoryBound(to: T.self)
            // Use it to initialize `buffer`.
            buffer = UnsafeMutableBufferPointer<T>.init(start: rawPtr, count: header.capacity)
        }
    }
    
    /// Computed property to access the value referenced by `headerPtr`.
    private var header: SharedVectorHeader {
        get { headerPtr.pointee }
        set {
            // Assign the new value
            headerPtr.pointee = newValue
            
            // Assign the new end index
            endIndex = header.size
        }
    }
    
    /// Property to access the buffer immediately after the header. Automatically kept in sync with `headerPtr`.
    private var buffer: UnsafeMutableBufferPointer<T>

    /// Deinitializer.
    deinit {
        // If there are other references, we don't do anything.
        guard header.refCount > 0 else { return }
        // Decrement the reference count
        header.refCount -= 1
        // If the reference count is EXACTLY 0, purge the content
        guard header.refCount == 0 else { return }
        // Purge content
        purgeContents()
        
        // Free the vector. Duplicated from `freeVector()`, because side-effects in deinitializer are forbidden.
        // Calcualte size and aligment
        let (size, alignment) = Self.calculateSizeAlignment(capacity: header.capacity)
        
        // Massage a pointer
        let ptrToFree: UnsafeMutablePointer<UInt8> = UnsafeMutableRawPointer(headerPtr).assumingMemoryBound(to: UInt8.self)
        
        // Tell Slint to free the vector
        slint_shared_vector_free(ptrToFree, size, alignment)
    }
    
    /// Copy values from another collection. Vector must already be large enough.
    @MainActor
    private func copyFromCollection<C>(_ items: C, startingAt startIndex: Int = 0)
        where C: Collection, C.Element == T // Collection with elements of the same type as us
    {
        precondition(startIndex + items.count < endIndex, "Attempted to copy values past the end of the vector.")
        
        for (index, value) in items.enumerated() {
            self[index + startIndex] = value
        }
        
        // Set size
        header.size = startIndex + items.count
    }
    
    /// SharedVector is copy-on-write. Call this before writing.
    @MainActor
    private func aboutToWrite(newCapacity: Int? = nil) {
        // If we're the only reference, and we don't need to resize, do nothing.
        guard (header.refCount > 1) && ((newCapacity ?? 0) > header.capacity) else { return }
        
        // Use a new capacity, if specified
        let capacity = newCapacity ?? header.capacity
        precondition(capacity >= header.capacity, "Tried to shrink a vector!")
        
        // Construct new SharedVector instance
        let tempSelf = Self()

        // Allocate new vector
        tempSelf.headerPtr = Self.newVector(capacity: capacity)
        
        // Use `copyFromCollection` to fill the new vector, cuz we conform to `Collection`
        tempSelf.copyFromCollection(self)
        
        // Decrement reference count and free our vector, if necessary
        header.refCount -= 1
        if header.refCount == 0 { freeVector() }
        
        // Assign the vector from the temporary instance to ourself
        headerPtr = tempSelf.headerPtr
        
        // Assign an empty vector to the temporary instance, so it doesn't free the new vector
        tempSelf.headerPtr = Self.getEmptyVector()
    }
    
    /// Purge all contents.
    private func purgeContents() { } // Value types don't get purged, see extension for reference types.
    
    /// Free the backing vector.
    @MainActor
    private func freeVector() {
        precondition(header.refCount == 0, "Tried to free a vector with references!")
        
        // Calcualte size and aligment
        let (size, alignment) = Self.calculateSizeAlignment(capacity: header.capacity)
        
        // Massage a pointer
        let ptrToFree: UnsafeMutablePointer<UInt8> = UnsafeMutableRawPointer(headerPtr).assumingMemoryBound(to: UInt8.self)
        
        // Tell Slint to free the vector
        slint_shared_vector_free(ptrToFree, size, alignment)
        
        // Assign the empty vector
        headerPtr = Self.getEmptyVector()
    }
    
    /// Check if two items are equal. This implementation is used for non-equatible types.
    fileprivate static func areEqual(_ a: T, _ b: T) -> Bool { false }
    
    /// Get the default empty vector.
    @MainActor
    fileprivate static func getEmptyVector() -> UnsafeMutablePointer<SharedVectorHeader> {
        // Returns a pointer to a pre-existing header called `SHARED_NULL` in `sharedvector.rs`, with a refCount of -1
        let emptyVecPtr: UnsafePointer<UInt8> = slint_shared_vector_empty()
        
        // Cast as SharedVectorHeader by converting to raw and assuming it's bound.
        return UnsafeMutableRawPointer(mutating: emptyVecPtr).assumingMemoryBound(to: SharedVectorHeader.self)
    }

    /// Allocate a vector with a specific capacity.
    @MainActor
    fileprivate static func newVector(capacity: Int) -> UnsafeMutablePointer<SharedVectorHeader> {
        // Calculate size/alignment
        let (size, alignment) = Self.calculateSizeAlignment(capacity: capacity)
        
        // Allocate a new vector
        let newVecPtr: UnsafeMutablePointer<UInt8> = slint_shared_vector_allocate(size, alignment)
        
        // Cast as SharedVectorHeader by converting to raw and assuming it's bound.
        let newVecHeader = UnsafeMutableRawPointer(newVecPtr).assumingMemoryBound(to: SharedVectorHeader.self)
        
        // Assign key fields. Apparently the Slint runtime doesn't do this, so the C++ bindings initialize the values.
        newVecHeader.pointee.refCount = 1
        newVecHeader.pointee.size = 0
        newVecHeader.pointee.capacity = capacity
        
        // Return the header pointer
        return newVecHeader
    }
    
    /// Helper function. Calculate the size and alignment for an allocation.
    fileprivate static func calculateSizeAlignment(capacity: Int) -> (size: UInt, alignment: UInt) {
        let size = (MemoryLayout<T>.size * capacity) + MemoryLayout<SharedVectorHeader>.size
        let alignment = MemoryLayout<SharedVectorHeader>.alignment
        return (UInt(size), UInt(alignment))
    }
}

/// Memory-management for when elements are objects, and need to be reference counted.
/// Specifically, store a reference-type with `Unmanaged.passRetained(…).takeUnretainedValue()`
/// Release a reference-type with `Unmanaged.passUnretained(…).release()`
extension SharedVector where T: AnyObject {
    /// Purge all contents.
    @MainActor
    private func purgeContents() {
        // Release all stored references.
        for element in buffer {
            Unmanaged.passUnretained(element).release()
        }
    }
    
    /// Return the value at a given index, specialized for reference types.
    @MainActor
    subscript(position: Int) -> T {
        get {
            precondition(position >= 0, "Index cannot be negative!")
            precondition(position < buffer.count, "Index out of bounds!")
            
            return buffer[position]
        }
        set {
            precondition(position >= 0, "Index cannot be negative!")
            precondition(position < buffer.count, "Index out of bounds!")
            
            // If the values are equal, do nothing
            if Self.areEqual(newValue, buffer[position]) { return }
            
            // Copy-on-write?
            aboutToWrite()
            
            // Release the old value
            Unmanaged.passUnretained(self[position]).release()
            
            // Retain the new value
            buffer[position] = Unmanaged.passUnretained(newValue).takeUnretainedValue()
        }
    }
}

extension SharedVector where T: Equatable {
    /// Check if two items are equal. This implementation is used for equatable types.
    fileprivate static func areEqual(_ a: T, _ b: T) -> Bool { a == b }
}
