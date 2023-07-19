//
//  Column.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 18/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public final class Column {
    public var alias: String?
    public var columnName: String
    public var tableName: String?
    public var schema: String?
    
    public var name: String {
        var column: String = ""
        if let databaseName = schema {
            column = databaseName + "."
        }
        if let tableName = tableName {
            column += tableName + "."
        }
        column += columnName
        return column
    }
    
    public init(_ name: String, alias: String? = nil, tableName: String? = nil, schema: String? = nil) {
        self.columnName = name
        self.alias = alias
        self.tableName = tableName
        self.schema = schema
    }
}

extension Column: CustomStringConvertible {
    public var description: String {
        return name
    }
}

extension Column: SQLSubExpression {
    public var parameters: [DatabaseValueConvertible?] {
        return []
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        if encryptedColumns.contains(columnName.lowercased()) {
            return "decrypt(\(columnName))"
        } else {
            return name
        }
    }
    #else
    public var expressionSQL: String {
        return name
    }
    #endif
}

public final class TableInfo {
    var tableName: String
    var alias: String?
    var databaseInfo: DatabaseInfo?
    
    var name: String {
        return alias ?? tableName
    }
    
    init(name: String, alias: String?) {
        self.tableName = name
        self.alias = alias
    }
}


public struct DatabaseInfo {
    let name: String
    let path: String
    
    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

extension DatabaseInfo: RowConvertible {
    public init(row: Row) {
        name = row["name"]
        path = row["file"]
    }
}

extension DatabaseInfo: CustomStringConvertible {
    public var description: String {
        return "[name: \(name), path: \(path)]"
    }
}
