//
//  Row.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 27/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation
#if SQLCipher
import SQLCipher
#else
import SQLite3
#endif

public final class Row {
    weak var statement: Statement?
    var columnNames: [String] = []
    var dbValues: [DatabaseValue] = []
    var lowercaseColumnIndexes: [String: Int] = [:]
    
    // init method used by row expressible
    public init(statement: Statement) {
        self.statement = statement
        columnNames = statement.columnNames
        lowercaseColumnIndexes = statement.columnIndexes
    }
    
    // init method used to generate row or [row]
    public init(statement: Statement, columnIndexes: [String: Int]) {
        self.statement = statement
        columnNames = statement.columnNames
        lowercaseColumnIndexes = statement.columnIndexes
        dbValues = (0..<statement.columnCount).map {
            DatabaseValue(sqliteStatement: statement.sqliteStatement, index: Int32($0))
        }
    }
    
    func index(ofColumn name: String) -> Int? {
        if let index = lowercaseColumnIndexes[name] {
            return index
        }
        return lowercaseColumnIndexes[name.lowercased()]
    }
    
    public func copy() -> Row {
        return Row(statement: statement!, columnIndexes: lowercaseColumnIndexes)
    }
    
    public func copy<T: Row>() -> T {
        return T(statement: statement!, columnIndexes: lowercaseColumnIndexes)
    }
    
    public subscript<T: DatabaseValueConvertible>(_ columnIndex: Int) -> T {
        return value(at: columnIndex)!
    }
    
    public subscript<T: DatabaseValueConvertible>(_ columnIndex: Int) -> T? {
        return value(at: columnIndex)
    }
    
    public subscript<T: DatabaseValueConvertible>(_ columnName: String) -> T {
        return value(forColumnName: columnName)!
    }
    
    public subscript<T: DatabaseValueConvertible>(_ columnName: String) -> T? {
        return value(forColumnName: columnName)
    }
    
    public subscript<T: DatabaseValueConvertible & StatementColumnConvertible>(_ index: Int) -> T {
        return try! value(at: index)!
    }
    
    public subscript<T: DatabaseValueConvertible & StatementColumnConvertible>(_ index: Int) -> T? {
        do {
            return try value(at: index)
        } catch {
            return nil
        }
    }
    
    public subscript<T: DatabaseValueConvertible & StatementColumnConvertible>(_ columnName: String) -> T {
        return try! value(forColumnName: columnName)!
    }
    
    public subscript<T: DatabaseValueConvertible & StatementColumnConvertible>(_ columnName: String) -> T? {
        do {
            return try value(forColumnName: columnName)
        } catch {
            return nil
        }
    }
    
    public func value<T: DatabaseValueConvertible>(at columnIndex: Int) -> T? {
        var value: DatabaseValue
        if let statement = statement {
            value = DatabaseValue(sqliteStatement: statement.sqliteStatement, index: Int32(columnIndex))
        } else {
            value = dbValues[columnIndex]
        }
        return T.fromDatabaseValue(value)
    }
    
    public func value<T: DatabaseValueConvertible>(forColumnName columnName: String) -> T? {
        guard let index = index(ofColumn: columnName) else { return nil }
        return value(at: index)
    }
    
    public func value<T: DatabaseValueConvertible & StatementColumnConvertible>(forColumnName columnName: String) throws -> T? {
        guard let index = index(ofColumn: columnName) else { return nil }
        return try value(at: index)
    }
    
    public func value<T: DatabaseValueConvertible & StatementColumnConvertible>(at columnIndex: Int) throws -> T? {
        let index = Int32(columnIndex)
        if let statement = statement {
            guard sqlite3_column_type(statement.sqliteStatement, index) != SQLITE_NULL else {
                return nil
            }
            return try T.init(sqliteStatement: statement.sqliteStatement, index: index)
        }
        return T.fromDatabaseValue(dbValues[columnIndex])
    }
}

extension Row: CustomStringConvertible {
    public var description: String {
        return "<Row "
            + (0..<columnNames.count).map { "\(columnNames[$0]):\(dbValues[$0])"}.joined(separator: " ")
            + ">"
    }
}

extension Row {
    public static func fetchAll(_ db: Database, query: SelectQueryProtocol) throws -> [Row] {
        return try db.query(query)
    }
    
    public static func fetchAll(_ db: Database, sql: SQL, parameters: DatabaseValueConvertible?...) throws -> [Row] {
        return try db.query(sql, parameters)
    }
    
    public static func fetchAll(_ db: Database, sql: SQL, parameters: [DatabaseValueConvertible?]) throws -> [Row] {
        return try db.query(sql, parameters)
    }
}

public protocol RowConvertible {
    init(row: Row) throws
}

extension RowConvertible {
    
    public static func fetchAll(_ db: Database, sql: SQL, parameters: DatabaseValueConvertible?...) throws -> [Self] {
        return try db.query(sql, parameters)
    }
    
    public static func fetchAll(_ db: Database, sql: SQL, parameters: [DatabaseValueConvertible?]) throws -> [Self] {
        return try db.query(sql, parameters)
    }
    
    public static func fetchAll(_ db: Database, query: SelectQueryProtocol) throws -> [Self] {
        return try db.query(query)
    }
    
//    public static func fetchAll(_ db: Database, sql: SQL, parameters: [String: DatabaseValueConvertible?]) throws -> [Self] {
//        return try db.query(sql, parameters)
//    }
    
    public static func fetchOne(_ db: Database, sql: SQL, parameters: DatabaseValueConvertible?...) throws -> Self? {
        return try db.query(sql, parameters)
    }
    
    public static func fetchOne(_ db: Database, sql: SQL, parameters: [DatabaseValueConvertible?]) throws -> Self? {
        return try db.query(sql, parameters)
    }
    
    public static func fetchOne(_ db: Database, query: SelectQueryProtocol) throws -> Self? {
        return try db.query(query)
    }
    
//    public static func fetchOne(_ db: Database, sql: SQL, parameters: [String: DatabaseValueConvertible?]) throws -> Self? {
//        return try db.query(sql, parameters)
//    }
    
}
