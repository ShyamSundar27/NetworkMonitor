//
//  Logger.swift
//  VTComponents
//
//  Created by Robin Rajasekaran on 24/01/20.
//  Copyright © 2020 Zoho Corp. All rights reserved.
//

import Foundation


open class Logger {
    
    public init() {
        
    }
    
    open func log(_ items: Any..., tag: String = "", flag: Flag = .debug, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        var tagStr = tag
        if !tagStr.isEmpty {
            tagStr = "[\(tagStr)]"
        }
        
        let fileName = URL(fileURLWithPath: "\(file)").lastPathComponent
        let time = formatter.string(from: Date())
        let log = "\(time) <\(fileName)> \(function) [Line \(line)]: \(tagStr) \(items)\n"
        Swift.print(log)
    }
    
    open func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if !condition() {
            let fileName = URL(fileURLWithPath: "\(file)").lastPathComponent
            let time = formatter.string(from: Date())
            let log = "\(time) <\(fileName)> \(function) [Line \(line)]: \(message())\n"
            assert(false, log)
        }
    }
    
    
    // MARK: -
    
    public enum Flag: Int {
        case error
        case warning
        case info
        case debug
        case verbose
    }
}


// MARK: -

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MM-yyyy hh:mm:ss.SSS"
    return formatter
}()


