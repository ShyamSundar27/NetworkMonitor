//
//  Serializable.swift
//  ZohoMail
//
//  Created by Sivakarthick M on 31/03/17.
//  Copyright © 2017 Zoho Corporation. All rights reserved.
//

import Foundation

public protocol Serializable {
    func toDict() -> [String: Any]
    func from(dict: [String: Any])
}

extension Serializable {

    public func toDict() -> [String: Any] {
        var dict = [String: Any]()
        let otherSelf = Mirror(reflecting: self)
        for child in otherSelf.children {
            if child.value is Array<Any> {
				let dic = child.value as! [Any]
				if let key = child.label {
					dict[key] = dic
				}
            } else if child.value is [String: Any] {
                let dic = child.value as! [String: Any]
                if let key = child.label {
                    dict[key] = ZJSONSerializer.string(from: dic)!
                }
            } else {
                let value: Any? = child.value
                if child.label != nil && value != nil {
                    dict[child.label!] = value!
                }
            }
        }
        return dict
    }

    public func from(dict: [String: Any]) {

    }
}
