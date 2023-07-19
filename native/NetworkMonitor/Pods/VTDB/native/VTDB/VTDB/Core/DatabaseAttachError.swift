//
//  DatabaseAttachError.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 19/02/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

public enum DatabaseAttachError: Error {
    case schemaAlreadyInUse(String)
    case schemaNotFound(String)
}

extension DatabaseAttachError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .schemaAlreadyInUse(let schema):
            return "DB attach error. Schema `\(schema)` alread in use"
        case .schemaNotFound(let schema):
            return "DB detach error. Schema `\(schema)` not found"
        }
    }
}

//extension DatabaseAttachError : CustomNSError {
//
//    /// NSError bridging: the domain of the error.
//    public static var errorDomain: String {
//        return "VTDB.DatabaseAttachError"
//    }

//    /// NSError bridging: the error code within the given domain.
//        public var errorCode: Int {
//            return Int(code)
//        }

//    /// NSError bridging: the user-info dictionary.
//    public var errorUserInfo: [String : Any] {
//        return [NSLocalizedDescriptionKey: description]
//    }
//}

