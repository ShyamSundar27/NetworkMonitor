//
//  UpdateQueryDefinition.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 17/04/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

final class UpdateQueryDefintion: QueryDefinition {
    var set: [String: SQLExpression] = [:]
    var conflictResolution: Database.ConflictResolution?
    var customSQL: CustomSQLExpression?
    
    func set(column: String, with expressions: SQLExpression) {
        set[column] = expressions
    }
    
    func set(_ columns: [String: DatabaseValueConvertible?]) {
        columns.forEach {
            set[$0.key] = $0.value
        }
    }
    
    func set(_ columns: [String: SQLExpression]) {
        columns.forEach {  set[$0.key] = $0.value}
    }
    
    func set(sql: String, parameters: [DatabaseValueConvertible?]) {
        customSQL = CustomSQLExpression(rawExpression: sql, parameters: parameters)
    }
    
    #if SQLEncrypted
    override func sql(_ db: Database) -> String {
        var encryptedColumns: Set<String> = []
        if case .table(let tableName, _) = source, let _ = db.encryption {
            encryptedColumns = try! db.encryptedColumns(in: tableName) ?? []
        }
        var query = "UPDATE"
        if let conflict = conflictResolution {
            query += " OR " + conflict.rawValue
        }
        query += " " + source.expressionSQL(db, encryptedColumns: encryptedColumns)
        query += " SET " + set.map {
            if encryptedColumns.contains($0.key.lowercased()) {
                if $0.value is SQLSubExpression {
                    return $0.key + " = encrypt(" + $0.value.expressionSQL(db, encryptedColumns: encryptedColumns) + ")"
                } else {
                    return $0.key + " = encrypt(?)"
                }
            } else {
                return $0.key + " = ?"
            }
            }.joined(separator: ", ")
        
        if let customSQL = customSQL {
            query.append(customSQL.expressionSQL(db, encryptedColumns: encryptedColumns))
        }
        
        if !filter.isEmpty {
            query += " WHERE " + filter.map {
                $0.expressionSQL(db, encryptedColumns: encryptedColumns)
                }.joined(separator: " AND ")
        }
        
        // check if limit is enabled
        if let _ = limit {
            if !orderBy.isEmpty {
                query += " ORDER BY " + orderBy.map {
                    $0.expressionSQL(db, encryptedColumns: encryptedColumns)
                }.joined(separator: ", ")
            }
            query += " LIMIT ?"
            if let _ = offset {
                query += " OFFSET ?"
            }
        }
        return query
    }
    #else
    override func sql() -> String {
        var query = "UPDATE"
        if let conflict = conflictResolution {
            query += " OR " + conflict.rawValue
        }
        query += " " + source.expressionSQL
        query += " SET " + set.map { $0.key + " = ?" }.joined(separator: ", ")
        if let customSQL = customSQL {
            query.append(customSQL.expressionSQL)
        }
        if !filter.isEmpty {
            query += " WHERE " + filter.map { $0.expressionSQL }.joined(separator: " AND ")
        }
        if limit != nil {
            if !orderBy.isEmpty {
                query += " ORDER BY " + orderBy.map { $0.expressionSQL }.joined(separator: ", ")
            }
            query += " LIMIT ?"
            if offset != nil {
                query += " OFFSET ?"
            }
        }
        return query
    }
    #endif
    
    override func parameters() -> [DatabaseValueConvertible?] {
        var parameters: [DatabaseValueConvertible?] = []
        set.forEach { parameters.append(contentsOf: $0.value.parameters) }
        if let customSQL = customSQL {
            parameters.append(contentsOf: customSQL.parameters)
        }
        add(expressions: filter, to: &parameters)
        add(expressions: orderBy, to: &parameters)
        if let limit = limit {
            parameters.append(limit)
            if let offset = offset {
                parameters.append(offset)
            }
        }
        return parameters
    }
}
