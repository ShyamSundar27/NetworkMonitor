//
//  DoubleLinkedList.swift
//  ZohoMail
//
//  Created by Robin Rajasekaran on 11/08/18.
//  Copyright © 2018 Zoho Corporation. All rights reserved.
//

import Foundation


public class DoubleLinkedList<Value> {

    fileprivate var head: Node<Value>?
    fileprivate var tail: Node<Value>?

    public var isEmpty: Bool {
        return (head == nil)
    }

    public var first: Node<Value>? {
        return head
    }

    public var last: Node<Value>? {
        return tail
    }

    public var values: [Value] {
        var arr: [Value] = []
        var node = head
        while node != nil {
            arr.append(node!.value)
            node = node!.next
        }
        return arr
    }

    public func insertAtTop(_ node: Node<Value>) {
        if head == nil {
            head = node
            tail = node
        } else {
            node.next = head
            head?.previous = node
            head = node
        }
    }

    public func append(_ node: Node<Value>) {
        if head == nil {
            head = node
        } else {
            tail?.next = node
            node.previous = tail
        }
        tail = node
    }
    
    public func removeNode(_ node: Node<Value>, comparator: (Node<Value>, Node<Value>) -> Bool = { $0 === $1 }) {
        var temp = head
        while temp != nil {
            let equal = comparator(node, temp!)
            if equal {
                // TODO: chat.. there was some crash in following due to force unwrapping. So removed all unwrapping
                if temp! === head! {
                    if head! === tail! {
                        head = nil
                        tail = nil
                    } else {
                        head = head?.next
                        head?.previous = nil
                    }
                } else if temp === tail! {
                    tail!.previous?.next = nil
                    tail = tail?.previous
                } else {
                    temp!.next?.previous = temp?.previous
                    temp!.previous?.next = temp?.next
                }
                break
            } else {
                temp = temp!.next
            }
        }
    }

    public func removeLast() {
        tail = tail?.previous
        tail?.next?.previous = nil
        tail?.next = nil
        if tail == nil {
            head = nil
        }
    }
    
    public func removeAll() {
        head = nil
        tail = nil
    }

    public func moveNodeToTop(_ node: Node<Value>) {
        guard head != nil else {
            return
        }

        guard head !== node else {
            return
        }

        if node === tail {
            tail = node.previous
        }
        node.next?.previous = node.previous
        node.previous?.next = node.next
        node.next = head
        node.previous = nil
        head?.previous = node
        head = node
    }
}


public class Node<Value> {

    public var value: Value
    public var next: Node<Value>?
    public weak var previous: Node<Value>?

    public init(value: Value) {
        self.value = value
    }
}


