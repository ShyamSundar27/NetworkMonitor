//
//  StatementColumnConvertible.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 20/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public protocol StatementColumnConvertible {
    init(sqliteStatement: SQLiteStatement, index: Int32) throws
}

extension DatabaseValueConvertible where Self: StatementColumnConvertible {
    
    public static func fetchOne(_ db: Database, sql: SQL, arguments: DatabaseValueConvertible?...) throws -> Self? {
        return try db.query(sql, arguments)
    }
    
    public static func fetchOne(_ db: Database, sql: SQL, arguments: [DatabaseValueConvertible?]) throws -> Self? {
        return try db.query(sql, arguments)
    }
    
    public static func fetchOne(_ db: Database, sql: SQL, arguments: [String: DatabaseValueConvertible?]) throws -> Self? {
        return try db.query(sql, arguments)
    }
    
    public static func fetchAll(_ db: Database, sql: SQL, arguments: DatabaseValueConvertible?...) throws -> [Self] {
        return try db.query(sql, arguments)
    }
    
    public static func fetchAll(_ db: Database, sql: SQL, arguments: [DatabaseValueConvertible?]) throws -> [Self] {
        return try db.query(sql, arguments)
    }
    
    public static func fetchAll(_ db: Database, sql: SQL, arguments: [String: DatabaseValueConvertible?]) throws -> [Self] {
        return try db.query(sql, arguments)
    }
    
}

