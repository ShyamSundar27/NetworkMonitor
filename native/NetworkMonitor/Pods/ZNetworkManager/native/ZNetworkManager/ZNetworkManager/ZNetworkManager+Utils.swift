//
//  ZNetworkManager+Utils.swift
//  ZNetworkManager
//
//  Created by Rahul T on 30/10/17.
//  Copyright © 2017 Rahul T. All rights reserved.
//

import Foundation

extension ZNetworkManager {
    
//    func acquireLock() {
//        lock.lock() ; defer { lock.unlock() }
//    }
    
    public static func formattedParamData(params: Dictionary<String,Any>) -> Data {
        
        var paramString : String = String()
        for (key, value) in params {
            
            //Key
            if(paramString.isEmpty) {
                paramString.append("\(key)")
            }
            else {
                paramString.append("&\(key)")
            }
            paramString.append("=")
            
            //Value
            if let valueArr = value as? [String] {
                if !valueArr.isEmpty {
                    let endIndex = valueArr.count - 1
                    for (index, valueStr) in valueArr.enumerated() {
                        paramString.append("\((valueStr).encodeValue())")
                        if index != endIndex {
                            paramString.append("&\(key)=")
                        }
                    }
                }
            }
            else{
                paramString.append("\(value)".encodeValue())
            }
        }
        #if DEBUG
        dlog("param: \(paramString)", flag: ZLog.Flag.verbose)
        #endif
        let paramData: Data = paramString.data(using: String.Encoding.ascii)!
        return paramData
    }
}
