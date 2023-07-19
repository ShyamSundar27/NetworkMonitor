//
//  LRUCache.swift
//  ZohoMail
//
//  Created by Robin Rajasekaran on 11/08/18.
//  Copyright © 2018 Zoho Corporation. All rights reserved.
//

import Foundation


public final class LRUCache<Key: Hashable, Value>: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var capacity = 5
    
    public var values: [Value] {
        return list.values
    }
    
    public var description: String {
        return "LRUCache: \(values)"
    }
    
    public var debugDescription: String {
        return description
    }
    
    private var dict: [Key: Node<Value>] = [:]
    private let list = DoubleLinkedList<Value>()
    private var currentCount = 0
    
    private let queue = DispatchQueue(label: "LRUCacheQueue")
    
    public init(capacity: Int) {
        self.capacity = capacity
    }
    
    public subscript(key: Key) -> Value? {
        set {
            queue.sync {
                if let oldNode = dict[key] {
                    list.moveNodeToTop(oldNode)
                    if let value = newValue {
                        oldNode.value = value
                    } else {
                        list.removeNode(oldNode)
                        dict[key] = nil
                        currentCount -= 1
                    }
                } else {
                    if let value = newValue {
                        let node = Node(value: value)
                        dict[key] = node
                        list.insertAtTop(node)
                        if currentCount == capacity {
                            list.removeLast()
                        } else {
                            currentCount += 1
                        }
                    }
                }
            }
        }
        
        get {
            var value: Value?
            queue.sync {
                if let node = dict[key] {
                    list.moveNodeToTop(node)
                    value = node.value
                } else {
                    value = nil
                }
            }
            return value
        }
    }
    
    public func removeAll() {
        queue.sync {
            currentCount = 0
            dict = [:]
            list.removeAll()
        }
    }
}


