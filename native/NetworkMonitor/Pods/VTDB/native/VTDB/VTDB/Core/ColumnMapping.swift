//
//  ColumnMapping.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 02/05/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

extension Database {
    public enum ColumnType: String {
        case int
        case int8
        case int16
        case int32
        case int64
        case uint
        case uint8
        case uint16
        case uint32
        case uint64
        case bool
        case float
        case double
        case character
        case string
        case date
        case data
        case url
        
        // DatabaseType
        case integer
        case real
        case text
        case blob
    }
}

extension Database.ColumnType {
    public func getDatabaseDatatype() -> String {
        switch self {
        case .integer, .int, .int8, .int16, .int32, .int64, .uint, .uint8, .uint16, .uint32, .uint64, .bool:
            return "INTEGER"
        case .real, .float, .double:
            return "REAL"
        case .blob, .data:
            return "BLOB"
        default: return "TEXT"
        }
    }
}

extension Database.ColumnType: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        return .text(self.rawValue)
    }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Database.ColumnType? {
        guard let string = String.fromDatabaseValue(dbValue) else {
            return nil
        }
        return Database.ColumnType(rawValue: string)
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Database.ColumnType? {
        guard let string = String.fromDatabaseValue(dbValue) else {
            return nil
        }
        return Database.ColumnType(rawValue: string)
    }
}

final class ColumnMapConstant {
    public static let sharedInstance = ColumnMapConstant()
    
    private init() { }
    
    let characterSet = CharacterSet(charactersIn: " \"\n'`()")
    let singleLine = makeRegex(pattern: "\\s+", options: nil)
    let nestedQuery = makeRegex(pattern: "\\(\\s*select.*?\\)")
    let keepOnlySelectColumn = makeRegex(pattern: "(select | from.*)(?=(?:[^\"]|\"[^\"]*\")*$)")
    // let commaSplit = makeRegex(pattern: "\"[^\"]*\"|(,)")
    let commaSplit = makeRegex(pattern: ",(?=(?:[^\"]|\"[^\"]*\")*$)", options: nil)
    let aliasSplit = makeRegex(pattern: "(\\s|\\bas\\b)(?=(?:[^\"]|\"[^\"]*\")*$)")
    let schemaSplit = makeRegex(pattern: "(\\s*\\.\\s*)(?=(?:[^\"]|\"[^\"]*\")*$)")
    let table = makeRegex(pattern: "(?<=(from|join) )(.*?)(?=\\b(inner|left|join|on|where|group|order|limit)\\b)")
    let lastTable = makeRegex(pattern: "(?:from |join )(?=(?:[^\"]|\"[^\"]*\")*$)")
    
    // experimental
    public let spaceSplit = makeRegex(pattern: " (?=(?:[^\"]|\"[^\"]*\")*$)", options: nil)
}

