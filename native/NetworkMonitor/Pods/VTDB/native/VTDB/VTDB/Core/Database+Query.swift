//
//  Query.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 08/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

extension Database {
    
    // MARK: DatabaseValueConvertible
    public func query<T: DatabaseValueConvertible>(_ sql: SQL) throws -> T? {
        let statement = try Statement(database: self, sql: sql)
        return try statement.query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: DatabaseValueConvertible?...) throws -> T? {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: [DatabaseValueConvertible?]) throws -> T? {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?]) throws -> T? {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ queryInterface: SelectQueryProtocol) throws -> T? {
        return try getStatement(for: queryInterface).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL) throws -> T {
        let statement = try Statement(database: self, sql: sql)
        return try statement.query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: DatabaseValueConvertible?...) throws -> T {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: [DatabaseValueConvertible?]) throws -> T {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?]) throws -> T {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ queryInterface: SelectQueryProtocol) throws -> T {
        return try getStatement(for: queryInterface).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL) throws -> [T?] {
        return try query(sql, [])
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: DatabaseValueConvertible?...) throws -> [T?] {
        return try query(sql, parameters)
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: [DatabaseValueConvertible?]) throws -> [T?] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?]) throws -> [T?] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ queryInterface: SelectQueryProtocol) throws -> [T?] {
        return try getStatement(for: queryInterface).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL) throws -> [T] {
        return try query(sql, [])
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: DatabaseValueConvertible?...) throws -> [T] {
        return try query(sql, parameters)
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: [DatabaseValueConvertible?]) throws -> [T] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?]) throws -> [T] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: DatabaseValueConvertible>(_ queryInterface: SelectQueryProtocol) throws -> [T] {
        return try getStatement(for: queryInterface).query()
    }
    
    // MARK: Dictionary - return nils
    public func fetch(_ sql: SQL, mapColumnType: [String: Database.ColumnType]? = nil) throws -> [[String: Any?]] {
        let statement = try Statement(database: self, sql: sql)
        if let mapColumnType = mapColumnType {
            return try statement.queryDict(columnType: mapColumnType)
        } else {
            return try statement.queryDict()
        }
    }
    
    public func fetch(_ sql: SQL, _ parameters: [DatabaseValueConvertible?], mapColumnType: [String: Database.ColumnType]? = nil) throws -> [[String: Any?]] {
        let statement = try Statement(database: self, sql: sql).bind(parameters)
        if let mapColumnType = mapColumnType {
            return try statement.queryDict(columnType: mapColumnType)
        } else {
            return try statement.queryDict()
        }
    }
    
    public func fetch(_ sql: SQL, _ parameters: DatabaseValueConvertible?..., mapColumnType: [String: Database.ColumnType]? = nil) throws -> [[String: Any?]] {
        return try fetch(sql, parameters, mapColumnType: mapColumnType)
    }
    
    public func fetch(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?], mapColumnType: [String: Database.ColumnType]? = nil) throws -> [[String: Any?]] {
        let statement = try Statement(database: self, sql: sql).bind(parameters)
        if let mapColumnType = mapColumnType {
            return try statement.queryDict(columnType: mapColumnType)
        } else {
            return try statement.queryDict()
        }
    }
    
    public func fetch(_ selectQuery: SelectQueryProtocol, mapColumnType: [String: Database.ColumnType]? = nil) throws -> [[String: Any?]] {
        let statement = try getStatement(for: selectQuery)
        if let mapColumnType = mapColumnType {
            return try statement.queryDict(columnType: mapColumnType)
        } else {
            return try statement.queryDict()
        }
    }
    
    // MARK: Dictionary - cast nil as Any or Empty String
    public func query(_ sql: SQL, mapColumnType: [String: Database.ColumnType]? = nil) throws -> [[String: Any]] {
        let statement = try Statement(database: self, sql: sql)
        if let mapColumnType = mapColumnType {
            return try statement.query(columnType: mapColumnType)
        } else {
            return try statement.query()
        }
    }
    
    public func query(_ sql: SQL, _ parameters: DatabaseValueConvertible?..., mapColumnType: [String: Database.ColumnType]? = nil) throws -> [[String: Any]] {
        let statement = try Statement(database: self, sql: sql).bind(parameters)
        if let mapColumnType = mapColumnType {
            return try statement.query(columnType: mapColumnType)
        } else {
            return try statement.query()
        }
    }
    
    public func query(_ sql: SQL, _ parameters: [DatabaseValueConvertible?], mapColumnType: [String: Database.ColumnType]? = nil) throws -> [[String: Any]] {
        let statement = try Statement(database: self, sql: sql).bind(parameters)
        if let mapColumnType = mapColumnType {
            return try statement.query(columnType: mapColumnType)
        } else {
            return try statement.query()
        }
    }
    
    public func query(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?], mapColumnType: [String: Database.ColumnType]? = nil) throws -> [[String: Any]] {
        let statement = try Statement(database: self, sql: sql).bind(parameters)
        if let mapColumnType = mapColumnType {
            return try statement.query(columnType: mapColumnType)
        } else {
            return try statement.query()
        }
    }
    
    public func query(_ selectQuery: SelectQueryProtocol, mapColumnType: [String: Database.ColumnType]? = nil) throws -> [[String: Any]] {
        let statement = try getStatement(for: selectQuery)
        if let mapColumnType = mapColumnType {
            return try statement.query(columnType: mapColumnType)
        } else {
            return try statement.query()
        }
    }
    
    public func query<T: Equatable & Hashable>(_ sql: SQL, groupBy field: String, mapColumnType: [String: Database.ColumnType]? = nil) throws -> [Section<T>] {
        let statement = try Statement(database: self, sql: sql)
        if let mapColumnType = mapColumnType {
            return try statement.query(columnType: mapColumnType, groupBy: field)
        } else {
            return try statement.query(groupBy: field)
        }
    }
    
    public func query<T: Equatable & Hashable>(_ sql: SQL, groupBy field: String, _ parameters: DatabaseValueConvertible?..., mapColumnType: [String: Database.ColumnType]? = nil) throws -> [Section<T>] {
        let statement = try Statement(database: self, sql: sql).bind(parameters)
        if let mapColumnType = mapColumnType {
            return try statement.query(columnType: mapColumnType, groupBy: field)
        } else {
            return try statement.query(groupBy: field)
        }
    }
    
    public func query<T: Equatable & Hashable>(_ sql: SQL, groupBy field: String, _ parameters: [DatabaseValueConvertible?], mapColumnType: [String: Database.ColumnType]? = nil) throws -> [Section<T>] {
        let statement = try Statement(database: self, sql: sql).bind(parameters)
        if let mapColumnType = mapColumnType {
            return try statement.query(columnType: mapColumnType, groupBy: field)
        } else {
            return try statement.query(groupBy: field)
        }
    }
    
    public func query<T: Equatable & Hashable>(_ sql: SQL, groupBy field: String, _ parameters: [String: DatabaseValueConvertible?], mapColumnType: [String: Database.ColumnType]? = nil) throws -> [Section<T>] {
        let statement = try Statement(database: self, sql: sql).bind(parameters)
        if let mapColumnType = mapColumnType {
            return try statement.query(columnType: mapColumnType, groupBy: field)
        } else {
            return try statement.query(groupBy: field)
        }
    }
    
    public func query<T: Equatable & Hashable>(_ selectQuery: SelectQueryProtocol, groupBy field: String, mapColumnType: [String: Database.ColumnType]? = nil) throws -> [Section<T>] {
        let statement = try getStatement(for: selectQuery)
        if let mapColumnType = mapColumnType {
            return try statement.query(columnType: mapColumnType, groupBy: field)
        } else {
            return try statement.query(groupBy: field)
        }
    }
    
    // MARK: RowConvertible
    public func query<T: RowConvertible>(_ sql: SQL) throws -> T {
        let statement = try Statement(database: self, sql: sql)
        return try statement.query()
    }
    
    public func query<T: RowConvertible>(_ sql: SQL, _ parameters: DatabaseValueConvertible?...) throws -> T {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: RowConvertible>(_ sql: SQL, _ parameters: [DatabaseValueConvertible?]) throws -> T {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: RowConvertible>(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?]) throws -> T {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: RowConvertible>(_ queryInterface: SelectQueryProtocol) throws -> T {
        return try getStatement(for: queryInterface).query()
    }
    
    public func query<T: RowConvertible>(_ sql: SQL) throws -> [T] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.query()
    }
    
    public func query<T: RowConvertible>(_ sql: SQL, _ parameters: DatabaseValueConvertible?...) throws -> [T] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: RowConvertible>(_ sql: SQL, _ parameters: [DatabaseValueConvertible?]) throws -> [T] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: RowConvertible>(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?]) throws -> [T] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: RowConvertible>(_ queryInterface: SelectQueryProtocol) throws -> [T] {
        return try getStatement(for: queryInterface).query()
    }
    
    // Todo: Needs more testing
    // MARK: Row
    public func query<T: Row>(_ sql: SQL) throws -> [T] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.query()
    }
    
    public func query<T: Row>(_ sql: SQL, _ parameters: DatabaseValueConvertible?...) throws -> [T] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: Row>(_ sql: SQL, _ parameters: [DatabaseValueConvertible?]) throws -> [T] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: Row>(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?]) throws -> [T] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: Row>(_ queryInterface: SelectQueryProtocol) throws -> [T] {
        return try getStatement(for: queryInterface).query()
    }
    
    // MARK: Any
    public func query<T: Any>(_ sql: SQL) throws -> [[T]] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.query()
    }

    public func query<T: Any>(_ sql: SQL, _ parameters: DatabaseValueConvertible?...) throws -> [[T]] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }

    public func query<T: Any>(_ sql: SQL, _ parameters: [DatabaseValueConvertible?]) throws -> [[T]] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }

    public func query<T: Any>(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?]) throws -> [[T]] {
        let statement = try Statement(database: self, sql: sql)
        return try statement.bind(parameters).query()
    }
    
    public func query<T: Any>(_ queryInterface: SelectQueryProtocol) throws -> [[T]] {
        return try getStatement(for: queryInterface).query()
    }
    
    // MARK: ZSQLite
    public func insert(intoTable table: String, values: [String: Any?], onConflict conflictResolution: Database.ConflictResolution? = nil) throws {
        let values = try castToDict(values)
        try insert(intoTable: table, values: values, onConflict: conflictResolution)
    }
    
    public func insert(intoTable table: String, values: [[String: Any?]], onConflict conflictResolution: Database.ConflictResolution? = nil) throws {
        let values = try castToListDict(values)
        try insert(intoTable: table, values: values, onConflict: conflictResolution)
        
    }
    
    public func insert(intoTable table: String, columns: [String], values: [[Any?]], onConflict conflictResolution: Database.ConflictResolution? = nil) throws {
        let values = try castToListOfList(values)
        try insert(intoTable: table, column: columns, values: values)
    }
    
    public func update(table name: String, with values: [String: Any?], where criteria: String? = nil, onConflict conflictResolution: Database.ConflictResolution? = nil) throws {
        let values = try castToDict(values)
        let query =  UpdateQuery(table: name).set(values)
        if let conflictResolution = conflictResolution {
            query.onConflict(conflictResolution)
        }
        if let criteria = criteria {
            query.filter(criteria)
        }
        try execute(query)
    }
    
    public func update(table name: String, with values: [String: Any?], where criteria: [String: Any?], onConflict conflictResolution: Database.ConflictResolution? = nil) throws {
        let values = try castToDict(values)
        let criteria = try castToDict(criteria)
        let query = UpdateQuery(table: name).set(values).filter(criteria)
        if let conflictResolution = conflictResolution {
            query.onConflict(conflictResolution)
        }
        try execute(query)
    }
    
    public func delete(fromTable table: String, where criteria: String? = nil) throws {
        let query = DeleteQuery(table: table)
        if let criteria = criteria {
            query.filter(criteria)
        }
        try execute(query)
    }
    
    public func delete(fromTable table: String, where criteria: [String: Any?]) throws {
        let criteria = try castToDict(criteria)
        let query = DeleteQuery(table: table).filter(criteria)
        try execute(query)
    }
    
    public func fetch(fromTable table: String, columns: [String], where criteria: [String: Any?]) throws -> [[String: Any]] {
        let criteria = try castToDict(criteria)
        let selectQuery = SelectQuery(table: table).select(columns).filter(criteria)
        return try query(selectQuery)
    }
    
    public func fetch(fromTable table: String, columns: [String], where criteria: String? = nil) throws -> [[String: Any]] {
        let selectQuery = SelectQuery(table: table).select(columns)
        if let criteria = criteria {
            selectQuery.filter(criteria)
        }
        return try query(selectQuery)
    }
    
    public func fetch(fromTable table: String) throws -> [[String: Any]] {
        let selectQuery = SelectQuery(table: table)
        return try query(selectQuery)
    }
    
    public func fetch<T: Equatable & Hashable>(fromTable table: String, columns: [String], where criteria: [String: Any?], groupBy field: String) throws -> [Section<T>] {
        let criteria = try castToDict(criteria)
        let selectQuery = SelectQuery(table: table).select(columns).filter(criteria)
        return try query(selectQuery, groupBy: field)
    }
    
    public func fetch<T: Equatable & Hashable>(fromTable table: String, columns: [String], where criteria: String? = nil, groupBy field: String) throws -> [Section<T>] {
        let selectQuery = SelectQuery(table: table)
        selectQuery.select(columns)
        if let criteria = criteria {
            selectQuery.filter(criteria)
        }
        return try query(selectQuery, groupBy: field)
    }
    
    public func fetch<T: Equatable & Hashable>(fromTable table: String, groupBy field: String) throws -> [Section<T>] {
        let selectQuery = SelectQuery(table: table)
        return try query(selectQuery, groupBy: field)
    }
    
    private func getStatement(for query: SelectQueryProtocol) throws -> Statement {
        #if SQLEncrypted
        let statement = try Statement(database: self, sql: query.expressionSQL(self, encryptedColumns: []))
        #else
        let statement = try Statement(database: self, sql: query.expressionSQL)
        #endif
        try statement.bind(query.parameters)
        return statement
    }
    
    // MARK: Cast methods
    func castToDict<T: Any>(_ value: T) throws -> [String: DatabaseValueConvertible?] {
        guard let values = value as? [String: DatabaseValueConvertible?] else {
            throw VTDBError.getCastError(actualType: type(of: value), expectedType: [String: DatabaseValueConvertible?].self)
        }
        return values
    }
    
    func castToListDict<T: Any>(_ value: T) throws -> [[String: DatabaseValueConvertible?]] {
        guard let values = value as? [[String: DatabaseValueConvertible?]] else {
            throw VTDBError.getCastError(actualType: type(of: value), expectedType: [[String: DatabaseValueConvertible?]].self)
        }
        return values
    }
    
    func castToList<T: Any>(_ value: T) throws -> [DatabaseValueConvertible?] {
        guard let values = value as? [DatabaseValueConvertible?] else {
            throw VTDBError.getCastError(actualType: type(of: value), expectedType: [DatabaseValueConvertible?].self)
        }
        return values
    }
    
    func castToListOfList<T: Any>(_ value: T) throws -> [[DatabaseValueConvertible?]] {
        guard let values = value as? [[DatabaseValueConvertible?]] else {
            throw VTDBError.getCastError(actualType: type(of: value), expectedType: [[DatabaseValueConvertible?]].self)
        }
        return values
    }
}
