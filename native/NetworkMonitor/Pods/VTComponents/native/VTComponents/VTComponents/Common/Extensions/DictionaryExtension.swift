//
//  DictionaryExtension.swift
//  VTComponents
//
//  Created by Robin Rajasekaran on 11/03/20.
//

import Foundation
import CoreGraphics // NOTE: imported for support of CGFloat in watchOS


extension Dictionary {
    
    public var allKeys: [Key] {
        return Array(keys)
    }
    
    public var allValues: [Value] {
        return Array(values)
    }
    
    public func intValue(forKey key: Key) -> Int? {
        if let value = self[key] as? Int {
            return value
        } else if let value = self[key] as? String, let valueInt = Int(value) {
            return valueInt
        }
        return nil
    }

    public func uintValue(forKey key: Key) -> UInt? {
        if let value = self[key] as? UInt {
            return value
        } else if let value = self[key] as? String, !value.hasPrefix("-"), let valueInt = UInt(value) {
            return valueInt
        } else {
            return nil
        }
    }

    public func doubleValue(forKey key: Key) -> Double? {
        if let value = self[key] as? Double {
            return value
        } else if let value = self[key] as? String, let valueDouble = Double(value) {
            return valueDouble
        }
        return nil
    }

    public func cgFloatValue(forKey key: Key) -> CGFloat? {
        if let value = self[key] as? Double {
            return CGFloat(value)
        } else if let value = self[key] as? Int {
            return CGFloat(value)
        } else if let value = self[key] as? String, let doubleValue = Double(value) {
            return CGFloat(doubleValue)
        }
        return nil
    }

    public func boolValue(forKey key: Key) -> Bool? {
        if let value = self[key] as? Bool {
            return value
        } else if let value = self[key] as? String {
            if value == "true" || value == "1" {
                return true
            } else if value == "false" || value == "0" {
                return false
            }
            return nil
        } else if let value = self[key] as? Int {
            return (value == 1)
        } else {
            return nil
        }
    }
}


