//
//  ZLogger.swift
//  ZohoMail
//
//  Created by Rahul T on 28/03/18.
//  Copyright © 2018 Zoho Corporation. All rights reserved.
//

import Foundation

extension ZNetworkManager {
    
    public struct ZLog {
        
        public let message: String
        public let tag: String?
        public var fileName: String?
        public let function: String
        public let line: Int
        public let flag: Flag
        
        public enum Flag: Int {
            case error
            case warning
            case info
            case debug
            case verbose
        }
    }
    
    
}

func dlog(_ items: Any..., tag: String? = nil, file: String = #file, function: String = #function, line: Int = #line, flag: ZNetworkManager.ZLog.Flag) {
    var log = ZNetworkManager.ZLog(message: "\(items)", tag: tag, fileName: nil, function: function, line: line, flag: flag)
    #if !os(watchOS)
    let fileName = URL(fileURLWithPath: file).lastPathComponent
    log.fileName = fileName
    #endif
    ZNetworkManager.sharedInstance.logger?(log)
}
