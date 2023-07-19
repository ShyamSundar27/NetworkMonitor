//
//  SafeReadWrite.swift
//  Pods
//
//  Created by Rahul T on 26/06/19.
//

import Foundation

public final class SafeReadWrite<T> {
    
    private var queue: DispatchQueue
    private var _value: T
    
    public init(_ value: T, label: String = "com.zoho.vtouch.SafeReadWrite." + UUID().uuidString) {
        self._value = value
        queue = DispatchQueue(label: label, attributes: DispatchQueue.Attributes.concurrent)
    }
    
    public var value: T {
        
        get {
            return read { $0 }
        }
        
        set {
            write { $0 = newValue }
        }
    }
    
    public func read<R>(_ block: (T) throws -> R) rethrows -> R {
        return try queue.sync {
            try block(_value)
        }
    }
    
    public func write(_ block: (inout T) throws -> Void) rethrows {
        try queue.sync(flags: DispatchWorkItemFlags.barrier) {
            try block(&_value)
        }
    }
}
