//
//  DatabaseError.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 08/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation
#if SQLCipher
import SQLCipher
#else
import SQLite3
#endif

public struct DatabaseError: Error {
    public let code: Int32
    public let sqliteError: SQLiteError
    public let extendedErrorCode: Int32
    public let message: String?
    public let sql: SQL?
    public let parameters: Any?
    
    init(code: Int32 = SQLITE_ERROR, message: String? = nil, sql: String? = nil, parameters: Any? = nil) {
        self.code = code
        self.extendedErrorCode = code
        self.message = message
        self.sql = sql
        self.parameters = parameters
        sqliteError = SQLiteError(rawValue: code) ?? .generic
    }
    
    init(database: Database, sql: String? = nil, parameters: Any? = nil) {
        code = database.lastErrorCode
        extendedErrorCode = database.lastExtendedErrorCode
        message = database.lastErrorMessage
        self.sql = sql
        self.parameters = parameters
        sqliteError = SQLiteError(rawValue: code) ?? .generic
    }
    
    public enum SQLiteError: Int32 {
        case generic = 1
        case `internal` = 2
        case permissionDenied = 3
        case abort = 4
        case databaseLocked = 5
        case tableLocked = 6
        case outOfMemory = 7
        case readOnlyDatabase = 8
        case interrupt = 9
        case diskIOError = 10
        case databaseCorrupt = 11
        case notFound = 12
        case full = 13
        case cantOpenDatabase = 14
        case `protocol` = 15
        case empty = 16 // not used
        case databaseSchemaChanged = 17
        case tooBig = 18
        case constraint = 19
        case datatypeMismatch = 20
        case misuse = 21
        case noLargeFileSupport = 22
        case authorizationDenied = 23
        case format = 24 // not used
        case bindOrColumnIndexOutOfRange = 25 // bind or column index out of range
        case notADatabase = 26
        case notice = 27 // used in log
        case warning = 28 // used in log
    }
}

extension DatabaseError: CustomStringConvertible {
    public var description: String {
        var description = "SQLite error \(code)"
        if let sql = sql {
            description += " with statement `\(sql)`"
        }
        if let parameters = parameters as? [DatabaseValueConvertible?] {
            description += " parameters \(parameters.compactMap { $0 })"
        } else if let parameters = parameters {
            description += " parameters \(parameters)"
        }
        if let message = message {
            description += ": \(message)"
        }
        return description
    }
}

extension DatabaseError : CustomNSError {
    
    /// NSError bridging: the domain of the error.
    public static var errorDomain: String {
        return "VTDB.DatabaseError"
    }
    
    /// NSError bridging: the error code within the given domain.
    public var errorCode: Int {
        return Int(code)
    }
    
    /// NSError bridging: the user-info dictionary.
    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: description]
    }
}
