//
//  InsertQuery.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 20/04/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

extension Database {

    public func insert(intoTable table: String, values: [DatabaseValueConvertible?], onConflict conflictResolution: ConflictResolution? = nil) throws {
        let sql = try makeInsertQuery(for: table, columnCount: values.count, onConflict: conflictResolution)
        try execute(sql, values)
    }
    
    public func insert(intoTable table: String, values: [[DatabaseValueConvertible?]], onConflict conflictResolution: ConflictResolution? = nil) throws {
        let sql = try makeInsertQuery(for: table, columnCount: values.first!.count, onConflict: conflictResolution)
        try execute(sql, values)
    }
    
    public func insert(intoTable table: String, values: [String: DatabaseValueConvertible?], onConflict conflictResolution: ConflictResolution? = nil) throws {
        let sql = try makeInsertQuery(for: table, columns: values.allKeys, onConflict: conflictResolution)
        try execute(sql, values.allValues)
    }
    
    public func insert(intoTable table: String, values: [[String: DatabaseValueConvertible?]], onConflict conflictResolution: ConflictResolution? = nil) throws {
        var cachedStatements: [String: Statement] = [:]
        for value in values {
            let sql = try makeInsertQuery(for: table, columns: value.allKeys, onConflict: conflictResolution)
            if let statement = cachedStatements[sql] {
                try execute(statement, value.allValues)
            } else {
                let statement = try Statement(database: self, sql: sql)
                cachedStatements[sql] = statement
                try execute(statement, value.allValues)
            }
        }
    }
    
    public func insert(intoTable table: String, column: [String], values: [[DatabaseValueConvertible?]], onConflict conflictResolution: ConflictResolution? = nil) throws {
        let sql = try makeInsertQuery(for: table, columns: column, onConflict: conflictResolution)
        try execute(sql, values)
    }
    
    private func makeInsertQuery(for table: String, columnCount: Int, onConflict conflictResolution: Database.ConflictResolution?) throws -> String {
        
        var query = "INSERT"
        if let conflictResolution = conflictResolution {
            query += " OR \(conflictResolution.rawValue)"
        }
        query += " INTO " + table + " VALUES ("
        #if SQLEncrypted
        if let _ =  encryption,
            let encryptedColumns = try encryptedColumns(in: table) {
            let columns = try self.columns(in: table)
            columns.forEach {
                if encryptedColumns.contains($0.name.lowercased()) {
                    query += "encrypt(?),"
                } else {
                    query += "?,"
                }
            }
        } else {
            query +=  String(repeating: "?,", count: columnCount)
        }
        #else
        query += String(repeating: "?,", count: columnCount)
        #endif
        query.removeLast()
        query += ")"
        return query
    }
    
    private func makeInsertQuery(for table: String, columns: [String], onConflict conflictResolution: Database.ConflictResolution?) throws -> String {
        var query = "INSERT"
        if let conflictResolution = conflictResolution {
            query += " OR \(conflictResolution.rawValue)"
        }
        query += " INTO " + table
        query += " (" + columns.joined(separator: ",")  + ")"
        query += " VALUES ("
        #if SQLEncrypted
        if let _ =  encryption,
            let encryptedColumns = try encryptedColumns(in: table) {
            columns.forEach {
                if encryptedColumns.contains($0.lowercased()) {
                    query += "encrypt(?),"
                } else {
                    query += "?,"
                }
            }
        } else {
            query += String(repeating: "?,", count: columns.count)
        }
        #else
        query += String(repeating: "?,", count: columns.count)
        #endif
        query.removeLast()
        query += ")"
        return query
    }
}
