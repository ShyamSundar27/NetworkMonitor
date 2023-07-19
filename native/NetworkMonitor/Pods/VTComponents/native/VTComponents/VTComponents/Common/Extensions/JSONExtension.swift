//
//  DictionaryExtension.swift
//  ZohoMail
//
//  Created by Robin Rajasekaran on 20/04/17.
//  Copyright © 2017 Zoho Corporation. All rights reserved.
//

import Foundation


public protocol JsonConvertible {
    var jsonData: Data? { get }
    var json: String? { get }
    
    static func from(JSONString: String) -> Item?
    
    associatedtype Item
}


public extension JsonConvertible {
    
    var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }
    
    var json: String? {
        guard let data = jsonData else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
}


extension Dictionary: JsonConvertible {
    
    public static func from(JSONString: String) -> [Key: Value]? {
        guard JSONString.length > 0 else {
            return nil
        }
        
        return (try? JSONSerialization.jsonObject(with: JSONString.data(using: .utf8)!, options: [])) as? [Key: Value]
    }
}


extension Array: JsonConvertible {
    
    public static func from(JSONString: String) -> [Element]? {
        guard JSONString.length > 0 else {
            return nil
        }
        
        return (try? JSONSerialization.jsonObject(with: JSONString.data(using: .utf8)!, options: [])) as? [Element]
    }
}


