//
//  ArrayExtension.swift
//  VTComponents-iOS
//
//  Created by Robin Rajasekaran on 20/04/20.
//

import Foundation


extension Array {
    
    public func enumerate(using closure: (Element, Int, inout Bool) -> Void) {
        var stop = false
        for index in stride(from: 0, to: count, by: 1) {
            closure(self[index], index, &stop)
            if stop {
                break
            }
        }
    }
    
    public func reverseEnumerate(using closure: (Element, Int, inout Bool) -> Void) {
        var stop = false
        for index in stride(from: count - 1, through: 0, by: -1) {
            closure(self[index], index, &stop)
            if stop {
                break
            }
        }
    }
    
    public func firstNElements(_ length: Int) -> Array<Element> {
        return Array(prefix(length))
    }
    
    public func filtered(using block: (Element) -> Bool) -> (filtered: [Element], remaining: [Element]) {
        var filtered: [Element] = []
        let remaining: [Element] = reduce(into: []) { (remaining, item) in
            let shouldInclude = block(item)
            if shouldInclude {
                filtered.append(item)
            } else {
                remaining.append(item)
            }
        }
        return (filtered, remaining)
    }
    
    /// Returns the first element which satisfies the given condition
    public func filterFirst(_ condition: (Element) throws -> Bool) rethrows -> Element? {
        for element in self where try condition(element) {
            return element
        }
        
        return nil
    }
    
    public mutating func move(at currentIndex: Int, to newIndex: Int) {
        let element = self[currentIndex]
        remove(at: currentIndex)
        insert(element, at: newIndex)
    }
    
    /// Returns the indices of elements which satisfy the given condition
    public func indices(where condition: (Element) throws -> Bool) rethrows -> [Int] {
        var result = [Int]()
        
        for index in 0..<self.count where try condition(self[index]) {
            result.append(index)
        }
        
        return result
    }
    
    /// Removes the first element which satisfies the given condition
    @inlinable public mutating func removeFirst(_ condition: (Element) throws -> Bool) rethrows {
        for (index, element) in self.enumerated() where try condition(element) {
            remove(at: index)
            return
        }
    }
    
    public func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}


public extension Array where Element: Equatable {
    
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        return result
    }
    
    func index(of findingElement: Element, after startOffset: Int) -> Int? {
        for i in startOffset ..< self.count {
            if self[i] == findingElement {
                return i
            }
        }
        return nil
    }
    
    mutating func remove(_ element: Element) {
        if let elementIndex = index(of: element) {
            self.remove(at: elementIndex)
        }
    }
    
    mutating func remove(contentsOf elementArray: [Element]) {
        for element in elementArray {
            if let elementIndex = index(of: element) {
                self.remove(at: elementIndex)
            }
        }
    }
}



